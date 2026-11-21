import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/groups/data/group_repository.dart';
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) => GroupRepository(ref.watch(supabaseClientProvider)));
final groupsFilterProvider = StateProvider<GroupFilter>((ref) => GroupFilter.all);
final groupCategoryFilterProvider = StateProvider<String?>((ref) => null);
final groupsViewProvider = StateProvider<bool>((ref) => false);
final groupsListProvider = AsyncNotifierProvider.autoDispose<GroupsNotifier, PagedState<Group>>(GroupsNotifier.new);

class GroupsNotifier extends PagedNotifier<Group> {
  @override
  Future<Page<Group>> fetchPage(PageCursor? cursor) async {
    final filter = ref.watch(groupsViewProvider) ? GroupFilter.mine : ref.watch(groupsFilterProvider);
    final session = await ref.watch(authSessionProvider.future);
    return ref.watch(groupRepositoryProvider).fetchGroups(filter: filter, userId: session?.user.id, category: ref.watch(groupCategoryFilterProvider), cursor: cursor);
  }
}

final groupBySlugProvider = FutureProvider.autoDispose.family<Group?, String>((ref, slug) async {
  final session = await ref.watch(authSessionProvider.future);
  return ref.watch(groupRepositoryProvider).getBySlug(slug, userId: session?.user.id);
});

final groupMembersProvider = FutureProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) => ref.watch(groupRepositoryProvider).fetchMembers(groupId));
final groupCategoriesProvider = FutureProvider<List<GroupCategory>>((ref) => ref.watch(groupRepositoryProvider).fetchCategories());
final groupStudioSummaryProvider = FutureProvider.autoDispose.family<GroupStudioSummary, String>((ref, groupId) => ref.watch(groupRepositoryProvider).studioSummary(groupId));
typedef GroupStatsRequest = ({String groupId, int days});
final groupStudioStatsProvider = FutureProvider.autoDispose.family<GroupStudioStats, GroupStatsRequest>((ref, request) => ref.watch(groupRepositoryProvider).studioStats(request.groupId, request.days));
final groupStudioPendingProvider = FutureProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) => ref.watch(groupRepositoryProvider).fetchStudioMembers(groupId, status: 'pending'));
final groupStudioMembersProvider = FutureProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) => ref.watch(groupRepositoryProvider).fetchStudioMembers(groupId, status: 'active'));
final groupStudioBannedProvider = FutureProvider.autoDispose.family<List<GroupMember>, String>((ref, groupId) => ref.watch(groupRepositoryProvider).fetchStudioMembers(groupId, status: 'banned'));
final groupPostsProvider = AsyncNotifierProvider.autoDispose.family<GroupPostsNotifier, PagedState<FeedPost>, String>((groupId) => GroupPostsNotifier(groupId));

class GroupPostsNotifier extends PagedNotifier<FeedPost> {
  final String groupId;

  GroupPostsNotifier(this.groupId);

  @override
  Future<Page<FeedPost>> fetchPage(PageCursor? cursor) => ref.watch(groupRepositoryProvider).fetchGroupPosts(groupId, cursor: cursor);

  void insertFirst(FeedPost post) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: [post, ...current.items.where((item) => item.id != post.id)]));
  }
}