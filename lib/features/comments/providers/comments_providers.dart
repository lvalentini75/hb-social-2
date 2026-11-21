import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/comments/data/comments_repository.dart';
import 'package:hb_social/features/comments/domain/post_comment.dart';

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) => CommentsRepository(ref.watch(supabaseClientProvider)));
final postCommentsProvider = AsyncNotifierProvider.autoDispose.family<PostCommentsNotifier, PagedState<Comment>, String>((postId) => PostCommentsNotifier(postId));

class PostCommentsNotifier extends PagedNotifier<Comment> {
  final String postId;
  PostCommentsNotifier(this.postId);

  @override
  Future<Page<Comment>> fetchPage(PageCursor? cursor) => ref.watch(commentsRepositoryProvider).fetchThread(postId, cursor: cursor);

  Future<Comment> create(String content, {String? parentId}) async {
    final comment = await ref.read(commentsRepositoryProvider).create(postId, content, parentId: parentId);
    final current = state.value ?? const PagedState<Comment>();
    if (parentId == null) {
      state = AsyncData(current.copyWith(items: [...current.items, comment]));
    } else {
      state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == parentId ? item.copyWith(replyCount: item.replyCount + 1, replies: [...item.replies, comment]) : item).toList()));
    }
    return comment;
  }

  Future<Comment> createGif(String gifUrl, {String? content, String? parentId}) async {
    final comment = await ref.read(commentsRepositoryProvider).createGif(postId, gifUrl, content: content, parentId: parentId);
    final current = state.value ?? const PagedState<Comment>();
    if (parentId == null) state = AsyncData(current.copyWith(items: [...current.items, comment]));
    else state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == parentId ? item.copyWith(replyCount: item.replyCount + 1, replies: [...item.replies, comment]) : item).toList()));
    return comment;
  }

  Future<void> insertRealtime(String id) async {
    final current = state.value;
    if (current == null || current.items.any((item) => item.id == id || item.replies.any((reply) => reply.id == id))) return;
    final comment = await ref.read(commentsRepositoryProvider).getById(id);
    if (comment.parentId == null) {
      state = AsyncData(current.copyWith(items: [...current.items, comment]));
      return;
    }
    var items = current.items;
    if (!items.any((item) => item.id == comment.parentId)) {
      final parent = await ref.read(commentsRepositoryProvider).getById(comment.parentId!);
      items = [...items, parent];
    }
    state = AsyncData(current.copyWith(items: items.map((item) => item.id == comment.parentId ? item.copyWith(replyCount: item.replyCount + 1, replies: [...item.replies, comment]) : item).toList()));
  }

  void deleteRealtime(String id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.where((item) => item.id != id).map((item) {
      final removed = item.replies.any((reply) => reply.id == id);
      return removed ? item.copyWith(replyCount: (item.replyCount - 1).clamp(0, 1 << 30), replies: item.replies.where((reply) => reply.id != id).toList()) : item;
    }).toList()));
  }

  Future<void> loadReplies(String parentId) async {
    final replies = await ref.read(commentsRepositoryProvider).fetchReplies(parentId);
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == parentId ? item.copyWith(replies: replies) : item).toList()));
  }

  Future<void> updateComment(String id, String content) async {
    final updated = await ref.read(commentsRepositoryProvider).update(id, content);
    _replace(updated);
  }

  Future<int> deleteComment(Comment comment) async {
    await ref.read(commentsRepositoryProvider).delete(comment.id);
    final current = state.value;
    if (current == null) return 0;
    if (comment.parentId == null) {
      state = AsyncData(current.copyWith(items: current.items.where((item) => item.id != comment.id).toList()));
      return -(1 + comment.replyCount);
    }
    state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == comment.parentId ? item.copyWith(replyCount: (item.replyCount - 1).clamp(0, 1 << 30), replies: item.replies.where((reply) => reply.id != comment.id).toList()) : item).toList()));
    return -1;
  }

  void applyLike(String id, bool liked, int count) => _mapComment(id, (comment) => comment.copyWith(myLike: liked, reactionCount: count));

  void removeAuthor(String authorId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.where((comment) => comment.authorId != authorId).map((comment) => comment.copyWith(replies: comment.replies.where((reply) => reply.authorId != authorId).toList())).toList()));
  }

  Future<void> reveal(String id) async {
    final current = state.value;
    if (current == null || current.items.any((item) => item.id == id || item.replies.any((reply) => reply.id == id))) return;
    final target = await ref.read(commentsRepositoryProvider).getById(id);
    if (target.parentId == null) {
      state = AsyncData(current.copyWith(items: [...current.items, target]));
      return;
    }
    final parent = await ref.read(commentsRepositoryProvider).getById(target.parentId!);
    final replies = await ref.read(commentsRepositoryProvider).fetchReplies(parent.id);
    final items = current.items.any((item) => item.id == parent.id) ? current.items : [...current.items, parent];
    state = AsyncData(current.copyWith(items: items.map((item) => item.id == parent.id ? item.copyWith(replies: replies) : item).toList()));
  }

  void _replace(Comment updated) => _mapComment(updated.id, (comment) => updated.copyWith(replies: comment.replies, replyCount: comment.replyCount));

  void _mapComment(String id, Comment Function(Comment) transform) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.map((item) {
      if (item.id == id) return transform(item);
      return item.copyWith(replies: item.replies.map((reply) => reply.id == id ? transform(reply) : reply).toList());
    }).toList()));
  }
}