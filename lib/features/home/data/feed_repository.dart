import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/feed/data/reaction_repository.dart';
import 'package:hb_social/features/feed/domain/reaction.dart' show PostReactionsInfo, ReactionSummary, ReactionTypeUi;
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/reels/data/reels_repository.dart';
import 'package:hb_social/features/pages/articles/data/articles_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FeedQueryFilter { forYou, following, nearby }

class FeedRepository {
  static const pageSize = 20;
  static const postSelect = '*,author:user_profiles!posts_author_id_fkey(id,username,display_name,avatar_url,verification_level),media:post_media(*),group:groups!group_id(id,slug,name,avatar_url),page:pages!page_id(id,slug,name,avatar_url,verification_status,category),hunting_unit:hunting_units(id,name),preview_comments:comments!post_id(id,content,reaction_count,created_at,author:user_profiles!author_id(id,username,display_name,avatar_url,verification_level)),shared:shared_post(*,author:user_profiles!posts_author_id_fkey(id,username,display_name,avatar_url,verification_level),media:post_media(*),group:groups!group_id(id,slug,name,avatar_url),page:pages!page_id(id,slug,name,avatar_url,verification_status,category),hunting_unit:hunting_units(id,name))';
  final SupabaseClient _client;
  final ReactionRepository _reactionRepository;

  FeedRepository(this._client) : _reactionRepository = ReactionRepository(_client);

  Future<Page<FeedPost>> getPosts({required FeedQueryFilter filter, required String countryCode, PageCursor? cursor}) async {
    try {
      final dynamic rows;
      if (filter == FeedQueryFilter.forYou) {
        rows = await _client.rpc('feed_for_you', params: {
          'p_country': countryCode,
          'p_limit': pageSize,
          'p_before_created_at': cursor?.createdAt.toUtc().toIso8601String(),
          'p_before_id': cursor?.id,
        }).isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published').select(postSelect).order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').order('created_at', ascending: false).order('id', ascending: false);
      } else {
        final function = filter == FeedQueryFilter.following ? 'feed_following' : 'feed_nearby';
        rows = await _client.rpc(function, params: {
          'p_limit': pageSize,
          'p_before_created_at': cursor?.createdAt.toUtc().toIso8601String(),
          'p_before_id': cursor?.id,
        }).isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published').select(postSelect).order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').order('created_at', ascending: false).order('id', ascending: false);
      }
      final items = await parsePosts(rows as List);
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Page<FeedPost>> fetchByAuthor({required String authorId, PageCursor? cursor}) async {
    try {
      var query = _client.from('posts').select(postSelect).eq('author_id', authorId).eq('status', 'published').isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published');
      query = applyCursor(query, cursor);
      final rows = await query.order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = await parsePosts(rows as List);
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Page<FeedPost>> fetchByHashtag({required String tag, PageCursor? cursor}) async {
    try {
      final hashtag = await _client.from('hashtags').select('id').eq('tag', tag.toLowerCase()).maybeSingle();
      if (hashtag == null) return const Page(items: []);
      final links = await _client.from('post_hashtags').select('post_id').eq('hashtag_id', hashtag['id'] as String);
      final ids = (links as List).map((row) => row['post_id'] as String).toList();
      if (ids.isEmpty) return const Page(items: []);
      var query = _client.from('posts').select(postSelect).inFilter('id', ids).eq('status', 'published').isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published');
      query = applyCursor(query, cursor);
      final rows = await query.order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = await parsePosts(rows as List);
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<int> hashtagPostCount(String tag) async {
    try {
      final row = await _client.from('hashtags').select('post_count').eq('tag', tag.toLowerCase()).maybeSingle();
      return (row?['post_count'] as num?)?.toInt() ?? 0;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<FeedPost?> getById(String id) async {
    try {
      final row = await _client.from('posts').select(postSelect).eq('id', id).eq('status', 'published').isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published').order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').maybeSingle();
      if (row == null) return null;
      return (await parsePosts([row])).first;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> sharePost(String originalId, String comment) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppException('errors.login_required');
    try {
      final original = await getById(originalId);
      if (original == null) throw const AppException('errors.not_found');
      final targetId = original.kind == 'share' ? original.sharedPostId : original.id;
      if (targetId == null) throw const AppException('errors.not_found');
      final profile = await _client.from('user_profiles').select('country_code').eq('id', user.id).single();
      await _client.from('posts').insert({
        'author_id': user.id,
        'kind': 'share',
        'shared_post_id': targetId,
        'content': comment.trim().isEmpty ? null : comment.trim(),
        'visibility': 'public',
        'status': 'published',
        'country_code': profile['country_code'],
      });
    } catch (error) {
      if (error is AppException) rethrow;
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Map<String, dynamic> _withPublicMedia(Map<String, dynamic> json) {
    json['media'] = ((json['media'] as List?) ?? const []).map((item) {
      final media = Map<String, dynamic>.from(item as Map);
      media['url'] = storagePublicUrl(_client, 'post-media', media['path'] as String?);
      media['thumbnail_url'] = storagePublicUrl(_client, 'post-media', media['thumbnail_path'] as String?);
      return media;
    }).toList();
    if (json['shared'] is Map) json['shared'] = _withPublicMedia(Map<String, dynamic>.from(json['shared'] as Map));
    if (json['group'] is Map) {
      final group = Map<String, dynamic>.from(json['group'] as Map);
      group['avatar_url'] = storagePublicUrl(_client, 'group-media', group['avatar_url'] as String?);
      json['group'] = group;
    }
    if (json['page'] is Map) {
      final page = Map<String, dynamic>.from(json['page'] as Map);
      page['avatar_url'] = storagePublicUrl(_client, 'page-media', page['avatar_url'] as String?);
      json['page'] = page;
    }
    return json;
  }

  /// Parses post rows. Reaction data is loaded ONCE per page through the
  /// `reactions_summary` RPC, in its own try/catch: a failure never fails the page.
  Future<List<FeedPost>> parsePosts(List rows) async {
    final jsonRows = rows.map((row) => _withPublicMedia(Map<String, dynamic>.from(row as Map))).toList();
    if (jsonRows.isNotEmpty) {
      final ids = jsonRows.map((row) => row['id'] as String).toList();
      try {
        final reelIds = jsonRows.where((row) => row['kind'] == 'reel').map((row) => row['id'] as String).toList();
        final videos = await ReelsRepository(_client).videosForPosts(reelIds);
        for (final row in jsonRows) { if (videos[row['id']] case final video?) row['reel_video'] = {'id': video.id, 'status': video.status, 'post_id': video.postId, 'caption': video.caption, 'thumbnail_url': video.thumbnailUrl, 'duration_s': video.durationSeconds, 'error': video.error, 'created_at': video.createdAt.toIso8601String(), 'submitted_at': video.submittedAt?.toIso8601String(), 'ready_at': video.readyAt?.toIso8601String(), 'view_count': video.viewCount}; }
      } catch (_) {}
      try {
        final articleIds = jsonRows.where((row) => row['kind'] == 'article' && row['article_id'] != null).map((row) => row['article_id'] as String).toList();
        final articles = await ArticlesRepository(_client).byIds(articleIds);
        for (final row in jsonRows) { if (articles[row['article_id']] case final article?) row['article'] = {
          'id': article.id, 'page_id': article.pageId, 'slug': article.slug, 'title': article.title, 'subtitle': article.subtitle, 'cover_path': article.coverPath, 'cover_url': article.coverUrl, 'status': article.status, 'scheduled_at': article.scheduledAt?.toIso8601String(), 'published_at': article.publishedAt?.toIso8601String(), 'post_id': article.postId, 'reading_time_min': article.readingTimeMin, 'view_count': article.viewCount, 'created_at': article.createdAt.toIso8601String(), 'updated_at': article.updatedAt.toIso8601String(), 'page': {'id': article.page.id, 'slug': article.page.slug, 'name': article.page.name, 'avatar_url': article.page.avatarUrl, 'verification_status': article.page.verificationStatus}, 'author': {'id': article.author.id, 'username': article.author.username, 'display_name': article.author.displayName}, 'post': {'reaction_count': article.reactionCount, 'comment_count': article.commentCount, 'share_count': article.shareCount, 'my_reaction': article.myReaction}, 'can_edit': article.canEdit,
        }; }
      } catch (_) {}
      try {
        final links = await _client.from('post_dogs').select('post_id,dog:dogs!dog_id(id,name,avatar_url)').inFilter('post_id', ids);
        final byPost = <String, List<Map<String, dynamic>>>{};
        for (final raw in links as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          if (row['dog'] is Map) byPost.putIfAbsent(row['post_id'] as String, () => []).add(Map<String, dynamic>.from(row['dog'] as Map));
        }
        for (final row in jsonRows) { row['dogs'] = byPost[row['id']] ?? const []; }
      } catch (_) {}
      try {
        final results = await Future.wait([_reactionRepository.summaryBatch(ids), _reactionRepository.namesBatch(ids)]);
        final info = results[0] as Map<String, PostReactionsInfo>;
        final names = results[1] as Map<String, String>;
        for (final row in jsonRows) {
          final entry = info[row['id'] as String];
          row['reaction_summary'] = (entry?.summary ?? const <ReactionSummary>[]).map((item) => {'type': item.type.value, 'count': item.count}).toList();
          row['my_reaction'] = entry?.myReaction;
          row['reaction_display_name'] = names[row['id'] as String];
        }
      } catch (_) {}
    }
    return jsonRows.map(FeedPost.fromJson).toList();
  }
}