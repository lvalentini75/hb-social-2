import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/comments/domain/post_comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsRepository {
  static const pageSize = 20;
  static const authorFields = 'id,username,display_name,avatar_url,verification_level,verified_at';
  static const commentFields = 'id,post_id,parent_id,author_id,content,gif_url,reaction_count,reply_count,created_at,author:user_profiles!author_id($authorFields)';
  final SupabaseClient _client;

  const CommentsRepository(this._client);

  Future<Page<Comment>> fetchThread(String postId, {PageCursor? cursor}) async {
    try {
      var query = _client.from('comments').select('$commentFields,replies:comments!parent_id($commentFields)').eq('post_id', postId).isFilter('parent_id', null).eq('status', 'published');
      if (cursor != null) {
        final time = cursor.createdAt.toUtc().toIso8601String();
        query = query.or('created_at.gt.$time,and(created_at.eq.$time,id.gt.${cursor.id})');
      }
      final rows = await query.order('created_at').order('id').order('created_at', referencedTable: 'replies').limit(3, referencedTable: 'replies').limit(pageSize);
      final items = (rows as List).map((row) => Comment.fromJson(Map<String, dynamic>.from(row as Map))).toList();
      return Page(items: await _withMyLikes(items), nextCursor: items.length == pageSize ? PageCursor(createdAt: items.last.createdAt, id: items.last.id) : null);
    } catch (error) { throw _map(error); }
  }

  Future<List<Comment>> fetchReplies(String parentId) async {
    try {
      final rows = await _client.from('comments').select(commentFields).eq('parent_id', parentId).eq('status', 'published').order('created_at').order('id');
      return _withMyLikes((rows as List).map((row) => Comment.fromJson(Map<String, dynamic>.from(row as Map))).toList());
    } catch (error) { throw _map(error); }
  }

  Future<Comment> getById(String id) async {
    try {
      final row = await _client.from('comments').select(commentFields).eq('id', id).single();
      return (await _withMyLikes([Comment.fromJson(Map<String, dynamic>.from(row))])).first;
    } catch (error) { throw _map(error); }
  }

  Future<Comment> create(String postId, String content, {String? parentId}) async {
    try {
      final result = await _client.rpc('create_comment', params: {'p_post_id': postId, 'p_content': content.trim(), 'p_parent_id': parentId});
      final id = result is String ? result : (result as Map)['id'] as String;
      return getById(id);
    } catch (error) { throw _map(error); }
  }

  Future<Comment> createGif(String postId, String gifUrl, {String? parentId, String? content}) async {
    try {
      final result = await _client.rpc('create_gif_comment', params: {'p_post_id': postId, 'p_gif_url': gifUrl, 'p_parent_id': parentId, 'p_content': content?.trim().isEmpty == true ? null : content?.trim()});
      return getById(result.toString());
    } catch (error) { throw _map(error); }
  }

  Future<Comment> update(String id, String content) async {
    try {
      await _client.from('comments').update({'content': content.trim()}).eq('id', id);
      return getById(id);
    } catch (error) { throw _map(error); }
  }

  Future<void> delete(String id) async {
    try { await _client.from('comments').delete().eq('id', id); } catch (error) { throw _map(error); }
  }

  Future<CommentLikeResult> toggleLike(String id) async {
    try {
      final result = await _client.rpc('toggle_comment_like', params: {'p_comment_id': id});
      final row = result is List ? Map<String, dynamic>.from(result.first as Map) : Map<String, dynamic>.from(result as Map);
      return CommentLikeResult(liked: row['liked'] as bool, likeCount: (row['like_count'] as num).toInt());
    } catch (error) { throw _map(error); }
  }

  Future<Set<String>> myLikes(List<String> ids) async {
    if (ids.isEmpty || _client.auth.currentUser == null) return {};
    try {
      final rows = await _client.from('comment_likes').select('comment_id').inFilter('comment_id', ids);
      return (rows as List).map((row) => row['comment_id'] as String).toSet();
    } catch (error) { throw _map(error); }
  }

  Future<List<PostAuthor>> searchMentions(String term) async {
    if (term.length < 2) return [];
    try {
      final safe = term.replaceAll(',', '').replaceAll('%', '');
      final rows = await _client.from('user_profiles').select(authorFields).eq('status', 'active').or('username.ilike.$safe%,display_name.ilike.$safe%').limit(5);
      return (rows as List).map((row) => PostAuthor.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) { throw _map(error); }
  }

  Future<List<Comment>> _withMyLikes(List<Comment> comments) async {
    final ids = [for (final comment in comments) comment.id, for (final comment in comments) ...comment.replies.map((reply) => reply.id)];
    final liked = await myLikes(ids);
    return comments.map((comment) => comment.copyWith(myLike: liked.contains(comment.id), replies: comment.replies.map((reply) => reply.copyWith(myLike: liked.contains(reply.id))).toList())).toList();
  }

  AppException _map(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('content_blocked') || message.contains('account_suspended')) return ErrorMapper.fromSupabase(error);
      if (message.contains('comment_content_required')) return const AppException('comment_errors.content_required');
      if (message.contains('comment_content_too_long')) return const AppException('comment_errors.content_too_long');
      if (message.contains('comment_parent_invalid')) return const AppException('comment_errors.parent_invalid');
      if (message.contains('comment_post_not_found') || message.contains('comment_not_found')) return const AppException('errors.not_found');
      if (message.contains('permission_denied')) return const AppException('errors.not_authorized');
      if (message.contains('not_authenticated')) return const AppException('errors.login_required');
    }
    return ErrorMapper.fromSupabase(error);
  }
}