import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/forums/data/forums_repository.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/domain/forum_reply.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/domain/forum_studio.dart';

enum ForumsTab { forums, recent, mine }

class ForumThreadQuery {
  final String filter;
  final String sort;
  final String? tag;
  final String? authorId;
  final String? authorName;
  final int? sinceDays;
  const ForumThreadQuery({this.filter = 'all', this.sort = 'activity', this.tag, this.authorId, this.authorName, this.sinceDays});
  ForumThreadQuery copyWith({String? filter, String? sort, String? tag, bool clearTag = false, String? authorId, String? authorName, bool clearAuthor = false, int? sinceDays, bool clearSince = false}) => ForumThreadQuery(filter: filter ?? this.filter, sort: sort ?? this.sort, tag: clearTag ? null : tag ?? this.tag, authorId: clearAuthor ? null : authorId ?? this.authorId, authorName: clearAuthor ? null : authorName ?? this.authorName, sinceDays: clearSince ? null : sinceDays ?? this.sinceDays);
}

final forumsRepositoryProvider = Provider<ForumsRepository>((ref) => ForumsRepository(ref.watch(supabaseClientProvider)));
final forumsTabProvider = StateProvider<ForumsTab>((ref) => ForumsTab.forums);
final forumCategoryFilterProvider = StateProvider<String?>((ref) => null);
final recentThreadQueryProvider = StateProvider<ForumThreadQuery>((ref) => const ForumThreadQuery());
final forumThreadQueryProvider = StateProvider.autoDispose.family<ForumThreadQuery, String>((ref, id) => const ForumThreadQuery());
final forumCategoriesProvider = FutureProvider<List<ForumCategory>>((ref) => ref.watch(forumsRepositoryProvider).fetchCategories());
final forumsProvider = AsyncNotifierProvider.autoDispose<ForumsNotifier, PagedState<Forum>>(ForumsNotifier.new);

class ForumsNotifier extends PagedNotifier<Forum> {
  @override
  Future<Page<Forum>> fetchPage(PageCursor? cursor) async {
    final session = await ref.watch(authSessionProvider.future);
    return ref.watch(forumsRepositoryProvider).fetchForums(countryCode: ref.watch(userSettingsProvider).countryCode ?? 'IT', userId: session?.user.id, category: ref.watch(forumCategoryFilterProvider), mine: ref.watch(forumsTabProvider) == ForumsTab.mine, cursor: cursor);
  }
}

final recentThreadsProvider = AsyncNotifierProvider.autoDispose<RecentThreadsNotifier, PagedState<ForumThread>>(RecentThreadsNotifier.new);

class RecentThreadsNotifier extends PagedNotifier<ForumThread> {
  @override
  Future<Page<ForumThread>> fetchPage(PageCursor? cursor) {
    final query = ref.watch(recentThreadQueryProvider);
    return ref.watch(forumsRepositoryProvider).fetchRecentThreads(countryCode: ref.watch(userSettingsProvider).countryCode ?? 'IT', offset: int.tryParse(cursor?.id ?? '') ?? 0, tag: query.tag, sort: query.sort);
  }
}

final forumDetailProvider = FutureProvider.autoDispose.family<Forum?, String>((ref, slug) async {
  final session = await ref.watch(authSessionProvider.future);
  return ref.watch(forumsRepositoryProvider).getBySlug(slug, userId: session?.user.id);
});

final threadsProvider = AsyncNotifierProvider.autoDispose.family<ThreadsNotifier, PagedState<ForumThread>, String>((forumId) => ThreadsNotifier(forumId));

class ThreadsNotifier extends PagedNotifier<ForumThread> {
  final String forumId;
  ThreadsNotifier(this.forumId);

  @override
  Future<Page<ForumThread>> fetchPage(PageCursor? cursor) {
    final query = ref.watch(forumThreadQueryProvider(forumId));
    return ref.watch(forumsRepositoryProvider).fetchThreads(forumId: forumId, offset: int.tryParse(cursor?.id ?? '') ?? 0, filter: query.filter, sort: query.sort, tag: query.tag, authorId: query.authorId, since: query.sinceDays == null ? null : DateTime.now().subtract(Duration(days: query.sinceDays!)));
  }
}

final threadDetailProvider = FutureProvider.autoDispose.family<ForumThread?, String>((ref, id) => ref.watch(forumsRepositoryProvider).getThread(id));
final threadSubscriptionProvider = FutureProvider.autoDispose.family<bool, String>((ref, id) => ref.watch(forumsRepositoryProvider).isThreadSubscribed(id));
final forumTopTagsProvider = FutureProvider.autoDispose.family<List<({String tag, int count})>, String>((ref, id) => ref.watch(forumsRepositoryProvider).topTags(id));
final forumStudioSummaryProvider = FutureProvider.autoDispose.family<ForumStudioSummary, String>((ref, id) => ref.watch(forumsRepositoryProvider).studioSummary(id));
final forumStudioPendingProvider = FutureProvider.autoDispose.family<List<ForumMember>, String>((ref, id) => ref.watch(forumsRepositoryProvider).fetchStudioMembers(id, status: 'pending'));
final forumStudioMembersProvider = FutureProvider.autoDispose.family<List<ForumMember>, String>((ref, id) => ref.watch(forumsRepositoryProvider).fetchStudioMembers(id, status: 'active'));
final forumStudioBannedProvider = FutureProvider.autoDispose.family<List<ForumMember>, String>((ref, id) => ref.watch(forumsRepositoryProvider).fetchStudioMembers(id, status: 'banned'));
final forumStudioThreadsProvider = FutureProvider.autoDispose.family<Page<ForumThread>, String>((ref, id) => ref.watch(forumsRepositoryProvider).fetchStudioThreads(id));
typedef ForumStatsRequest = ({String forumId, int days});
typedef ForumReportsRequest = ({String forumId, bool openOnly});
final forumStudioStatsProvider = FutureProvider.autoDispose.family<ForumStudioStats, ForumStatsRequest>((ref, request) => ref.watch(forumsRepositoryProvider).studioStats(request.forumId, request.days));
final forumReportsProvider = FutureProvider.autoDispose.family<List<ForumReport>, ForumReportsRequest>((ref, request) => ref.watch(forumsRepositoryProvider).forumReports(request.forumId, openOnly: request.openOnly));
final repliesProvider = AsyncNotifierProvider.autoDispose.family<RepliesNotifier, PagedState<ForumReply>, String>((threadId) => RepliesNotifier(threadId));

class RepliesNotifier extends PagedNotifier<ForumReply> {
  final String threadId;
  RepliesNotifier(this.threadId);

  @override
  Future<Page<ForumReply>> fetchPage(PageCursor? cursor) => ref.watch(forumsRepositoryProvider).fetchReplies(threadId: threadId, cursor: cursor);

  @override
  Future<void> loadMore() async {
    await super.loadMore();
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: _treeOrder(current.items)));
  }

  void insert(ForumReply reply) {
    final current = state.value;
    if (current == null) return;
    final items = [...current.items];
    final parentIndex = reply.parentId == null ? -1 : items.indexWhere((item) => item.id == reply.parentId);
    final depth = parentIndex < 0 ? 0 : (items[parentIndex].depth + 1).clamp(0, 2);
    final inserted = reply.copyWith(depth: depth);
    if (parentIndex < 0) {
      items.add(inserted);
    } else {
      var index = parentIndex + 1;
      while (index < items.length && items[index].depth > items[parentIndex].depth) { index++; }
      items.insert(index, inserted);
    }
    state = AsyncData(current.copyWith(items: items));
  }

  void replaceReply(ForumReply reply, {required bool canManage}) {
    final current = state.value;
    if (current == null) return;
    if (reply.status == 'hidden' && !canManage) { remove(reply.id); return; }
    state = AsyncData(current.copyWith(items: [for (final item in current.items) item.id == reply.id ? reply.copyWith(depth: item.depth) : item]));
  }

  void updateLike(String id, bool liked, int count) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: [for (final item in current.items) item.id == id ? item.copyWith(myLike: liked, reactionCount: count) : item]));
  }

  void remove(String id) {
    final current = state.value;
    if (current == null) return;
    final removed = <String>{id};
    var changed = true;
    while (changed) { changed = false; for (final item in current.items) { if (item.parentId != null && removed.contains(item.parentId) && removed.add(item.id)) changed = true; } }
    state = AsyncData(current.copyWith(items: current.items.where((item) => !removed.contains(item.id)).toList()));
  }

  List<ForumReply> _treeOrder(List<ForumReply> replies) {
    final byParent = <String?, List<ForumReply>>{};
    for (final reply in replies) { (byParent[reply.parentId] ??= []).add(reply); }
    final result = <ForumReply>[];
    void append(String? parentId, int depth) {
      for (final reply in byParent[parentId] ?? const <ForumReply>[]) { result.add(reply.copyWith(depth: depth.clamp(0, 2))); append(reply.id, depth + 1); }
    }
    append(null, 0);
    for (final reply in replies) { if (!result.any((item) => item.id == reply.id)) result.add(reply); }
    return result;
  }
}