import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/pages/data/page_repository.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';

enum PagesView { discover, mine }

final pageRepositoryProvider = Provider<PageRepository>((ref) => PageRepository(ref.watch(supabaseClientProvider)));
final pagesViewProvider = StateProvider<PagesView>((ref) => PagesView.discover);
final pagesCategoryProvider = StateProvider<String?>((ref) => null);
final pageCategoriesProvider = FutureProvider<List<PageCategory>>((ref) => ref.watch(pageRepositoryProvider).fetchCategories());
final pagesListProvider = AsyncNotifierProvider.autoDispose<PagesNotifier, PagedState<CommunityPage>>(PagesNotifier.new);
final myPagesProvider = FutureProvider.autoDispose<List<CommunityPage>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return const [];
  return ref.watch(pageRepositoryProvider).fetchMyPages();
});

class PagesNotifier extends PagedNotifier<CommunityPage> {
  @override
  Future<Page<CommunityPage>> fetchPage(PageCursor? cursor) => ref.watch(pageRepositoryProvider).fetchPages(category: ref.watch(pagesCategoryProvider), cursor: cursor);
}

final pageBySlugProvider = FutureProvider.autoDispose.family<CommunityPage?, String>((ref, slug) async {
  final session = await ref.watch(authSessionProvider.future);
  return ref.watch(pageRepositoryProvider).fetchBySlug(slug, userId: session?.user.id);
});
final pageStudioSummaryProvider = FutureProvider.autoDispose.family<PageStudioSummary?, String>((ref, pageId) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return null;
  return ref.watch(pageRepositoryProvider).studioSummary(pageId);
});
final pageTeamProvider = FutureProvider.autoDispose.family<List<PageTeamMember>, String>((ref, pageId) => ref.watch(pageRepositoryProvider).fetchTeam(pageId));
typedef PageStatsRequest = ({String pageId, int days});
final pageStudioStatsProvider = FutureProvider.autoDispose.family<PageStudioStats, PageStatsRequest>((ref, request) => ref.watch(pageRepositoryProvider).studioStats(request.pageId, request.days));

final pagePostsProvider = AsyncNotifierProvider.autoDispose.family<PagePostsNotifier, PagedState<FeedPost>, String>((pageId) => PagePostsNotifier(pageId));

class PagePostsNotifier extends PagedNotifier<FeedPost> {
  final String pageId;
  PagePostsNotifier(this.pageId);

  @override
  Future<Page<FeedPost>> fetchPage(PageCursor? cursor) => ref.watch(pageRepositoryProvider).fetchPagePosts(pageId, cursor: cursor);

  void insertFirst(FeedPost post) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: [post, ...current.items.where((item) => item.id != post.id)]));
  }
}