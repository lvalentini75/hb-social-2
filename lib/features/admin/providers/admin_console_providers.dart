import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_list_repository.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_category.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';

extension AdminAsyncValueCompat<T> on AsyncValue<T> {
  T? get valueOrNull => value;
}

final adminListRepositoryProvider = Provider<AdminListRepository>((ref) => AdminListRepository(ref.watch(supabaseClientProvider)));

final adminUsersProvider = AsyncNotifierProvider.autoDispose.family<AdminUsersNotifier, PagedState<AdminUserRecord>, AdminUserFilters>((filters) => AdminUsersNotifier(filters));
final adminUsersCountProvider = FutureProvider.autoDispose.family<int, AdminUserFilters>((ref, filters) => ref.watch(adminListRepositoryProvider).countUsers(filters));
final adminUserDetailProvider = FutureProvider.autoDispose.family<AdminUserDetail, String>((ref, id) => ref.watch(adminListRepositoryProvider).fetchUserDetail(id));

class AdminUsersNotifier extends PagedNotifier<AdminUserRecord> {
  final AdminUserFilters filters;
  AdminUsersNotifier(this.filters);
  @override Future<Page<AdminUserRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchUsers(filters: filters, cursor: cursor)).page;
}

final adminReportsProvider = AsyncNotifierProvider.autoDispose.family<AdminReportsNotifier, PagedState<AdminReportRecord>, AdminReportFilters>((filters) => AdminReportsNotifier(filters));
final adminReportsCountProvider = FutureProvider.autoDispose.family<int, AdminReportFilters>((ref, filters) => ref.watch(adminListRepositoryProvider).countReports(filters));
final adminReportPreviewProvider = FutureProvider.autoDispose.family<AdminReportPreview, AdminReportRecord>((ref, report) => ref.watch(adminListRepositoryProvider).fetchReportPreview(report));

class AdminReportsNotifier extends PagedNotifier<AdminReportRecord> {
  final AdminReportFilters filters;
  AdminReportsNotifier(this.filters);
  @override Future<Page<AdminReportRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchReports(filters: filters, cursor: cursor)).page;
}

final adminApprovalsProvider = AsyncNotifierProvider.autoDispose.family<AdminApprovalsNotifier, PagedState<AdminVerificationRequest>, AdminApprovalFilters>((filters) => AdminApprovalsNotifier(filters));
final adminVerificationStatsProvider = FutureProvider.autoDispose<AdminVerificationStats>((ref) => ref.watch(adminListRepositoryProvider).fetchVerificationStats());
final adminVerificationHistoryProvider = FutureProvider.autoDispose.family<List<AdminVerificationRequest>, ({String userId, String currentId})>((ref, value) => ref.watch(adminListRepositoryProvider).fetchVerificationHistory(value.userId, value.currentId));

class AdminApprovalsNotifier extends PagedNotifier<AdminVerificationRequest> {
  final AdminApprovalFilters filters;
  int count = 0;
  AdminApprovalsNotifier(this.filters);
  @override Future<Page<AdminVerificationRequest>> fetchPage(PageCursor? cursor) async {
    final result = await ref.read(adminListRepositoryProvider).fetchApprovals(filters: filters, cursor: cursor);
    count = result.count;
    return result.page;
  }
}

final adminListingsProvider = AsyncNotifierProvider.autoDispose.family<AdminListingsNotifier, PagedState<AdminListingRecord>, AdminListingFilters>((filters) => AdminListingsNotifier(filters));
final adminListingsCountProvider = FutureProvider.autoDispose.family<int, AdminListingFilters>((ref, filters) => ref.watch(adminListRepositoryProvider).countListings(filters));
final adminListingDetailProvider = FutureProvider.autoDispose.family<AdminListingDetail, Listing>((ref, listing) => ref.watch(adminListRepositoryProvider).fetchListingDetail(listing));
final adminMarketplaceCategoriesProvider = FutureProvider.autoDispose<List<MarketplaceCategory>>((ref) => ref.watch(marketplaceRepositoryProvider).fetchCategories(country: 'IT'));

class AdminListingsNotifier extends PagedNotifier<AdminListingRecord> {
  final AdminListingFilters filters;
  AdminListingsNotifier(this.filters);
  @override Future<Page<AdminListingRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchListings(filters: filters, cursor: cursor)).page;
}

final adminCalendarsProvider = AsyncNotifierProvider.autoDispose.family<AdminCalendarsNotifier, PagedState<AdminCalendarRecord>, AdminCalendarFilters>((filters) => AdminCalendarsNotifier(filters));
final adminCalendarsCountProvider = FutureProvider.autoDispose.family<int, AdminCalendarFilters>((ref, filters) => ref.watch(adminListRepositoryProvider).countCalendars(filters));
final adminCalendarOptionsProvider = FutureProvider.autoDispose<AdminCalendarOptions>((ref) => ref.watch(adminListRepositoryProvider).fetchCalendarOptions());
final adminSpeciesProvider = FutureProvider.autoDispose<List<AdminSpeciesRecord>>((ref) => ref.watch(adminListRepositoryProvider).fetchSpecies());

class AdminCalendarsNotifier extends PagedNotifier<AdminCalendarRecord> {
  final AdminCalendarFilters filters;
  AdminCalendarsNotifier(this.filters);
  @override Future<Page<AdminCalendarRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchCalendars(filters: filters, cursor: cursor)).page;
}

final adminRolesDataProvider = FutureProvider.autoDispose<AdminRolesData>((ref) => ref.watch(adminListRepositoryProvider).fetchRolesData());
final adminPlatformConfigurationProvider = FutureProvider.autoDispose<AdminPlatformConfiguration>((ref) => ref.watch(adminListRepositoryProvider).fetchPlatformConfiguration());
final adminCountryPoliciesProvider = FutureProvider.autoDispose<List<AdminCountryPolicyOverview>>((ref) => ref.watch(adminListRepositoryProvider).fetchCountryPoliciesOverview());
final adminAuditOptionsProvider = FutureProvider.autoDispose<AdminAuditOptions>((ref) => ref.watch(adminListRepositoryProvider).fetchAuditOptions());

final adminAuditProvider = AsyncNotifierProvider.autoDispose.family<AdminAuditNotifier, PagedState<AdminAuditRecord>, AdminAuditFilters>((filters) => AdminAuditNotifier(filters));

final adminPostsProvider = AsyncNotifierProvider.autoDispose.family<AdminPostsNotifier, PagedState<AdminPostRecord>, AdminContentFilters>((filters) => AdminPostsNotifier(filters));
final adminStoriesProvider = AsyncNotifierProvider.autoDispose.family<AdminStoriesNotifier, PagedState<AdminStoryRecord>, AdminContentFilters>((filters) => AdminStoriesNotifier(filters));
final adminCommentsProvider = AsyncNotifierProvider.autoDispose.family<AdminCommentsNotifier, PagedState<AdminCommentRecord>, AdminContentFilters>((filters) => AdminCommentsNotifier(filters));
final adminContentCountProvider = FutureProvider.autoDispose.family<int, ({String table, AdminContentFilters filters})>((ref, value) => ref.watch(adminListRepositoryProvider).countAdminContent(value.table, value.filters));
final adminPostDetailProvider = FutureProvider.autoDispose.family<AdminPostDetail, String>((ref, id) => ref.watch(adminListRepositoryProvider).fetchAdminPostDetail(id));

class AdminPostsNotifier extends PagedNotifier<AdminPostRecord> {
  final AdminContentFilters filters;
  AdminPostsNotifier(this.filters);
  @override Future<Page<AdminPostRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchAdminPosts(filters: filters, cursor: cursor)).page;
}

class AdminStoriesNotifier extends PagedNotifier<AdminStoryRecord> {
  final AdminContentFilters filters;
  AdminStoriesNotifier(this.filters);
  @override Future<Page<AdminStoryRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchAdminStories(filters: filters, cursor: cursor)).page;
}

class AdminCommentsNotifier extends PagedNotifier<AdminCommentRecord> {
  final AdminContentFilters filters;
  AdminCommentsNotifier(this.filters);
  @override Future<Page<AdminCommentRecord>> fetchPage(PageCursor? cursor) async => (await ref.read(adminListRepositoryProvider).fetchAdminComments(filters: filters, cursor: cursor)).page;
}

final adminCommunitiesProvider = AsyncNotifierProvider.autoDispose.family<AdminCommunitiesNotifier, PagedState<AdminCommunityRecord>, AdminCommunityFilters>((filters) => AdminCommunitiesNotifier(filters));
final adminEventsProvider = AsyncNotifierProvider.autoDispose.family<AdminEventsNotifier, PagedState<AdminEventRecord>, AdminCommunityFilters>((filters) => AdminEventsNotifier(filters));
final adminCommunityDetailProvider = FutureProvider.autoDispose.family<AdminCommunityDetail, AdminCommunityRecord>((ref, value) => ref.watch(adminListRepositoryProvider).fetchAdminCommunityDetail(value));
final adminEventDetailProvider = FutureProvider.autoDispose.family<AdminEventDetail, String>((ref, id) => ref.watch(adminListRepositoryProvider).fetchAdminEventDetail(id));

class AdminCommunitiesNotifier extends PagedNotifier<AdminCommunityRecord> {
  final AdminCommunityFilters filters;
  int count = 0;
  AdminCommunitiesNotifier(this.filters);
  @override Future<Page<AdminCommunityRecord>> fetchPage(PageCursor? cursor) async { final result = await ref.read(adminListRepositoryProvider).fetchAdminCommunities(filters: filters, cursor: cursor); count = result.count; return result.page; }
}

class AdminEventsNotifier extends PagedNotifier<AdminEventRecord> {
  final AdminCommunityFilters filters;
  int count = 0;
  AdminEventsNotifier(this.filters);
  @override Future<Page<AdminEventRecord>> fetchPage(PageCursor? cursor) async { final result = await ref.read(adminListRepositoryProvider).fetchAdminEvents(filters: filters, cursor: cursor); count = result.count; return result.page; }
}

class AdminAuditNotifier extends PagedNotifier<AdminAuditRecord> {
  final AdminAuditFilters filters;
  int count = 0;
  AdminAuditNotifier(this.filters);
  @override Future<Page<AdminAuditRecord>> fetchPage(PageCursor? cursor) async {
    final result = await ref.read(adminListRepositoryProvider).fetchAuditLog(filters: filters, cursor: cursor);
    count = result.count;
    return result.page;
  }
}