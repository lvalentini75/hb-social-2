import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_p43_repository.dart';
import 'package:hb_social/features/admin/domain/admin_p43_models.dart';

final adminP43RepositoryProvider = Provider<AdminP43Repository>((ref) => AdminP43Repository(ref.watch(supabaseClientProvider)));
final adminFeatureFlagsProvider = FutureProvider.autoDispose<List<AdminFeatureFlagRecord>>((ref) => ref.watch(adminP43RepositoryProvider).featureFlags());
final adminEmailTemplatesProvider = FutureProvider.autoDispose<List<AdminEmailTemplate>>((ref) => ref.watch(adminP43RepositoryProvider).emailTemplates());
final adminCronJobsProvider = FutureProvider.autoDispose<List<AdminCronJob>>((ref) => ref.watch(adminP43RepositoryProvider).cronJobs());
final adminBroadcastsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(adminP43RepositoryProvider).broadcasts());
final adminSupportStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP43RepositoryProvider).supportStats());
final adminTranslationStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP43RepositoryProvider).translationStats());
final adminDeeplUsageProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP43RepositoryProvider).deeplUsage());
final adminAuthStatsProvider = FutureProvider.autoDispose.family<AdminAuthStats, int>((ref, days) => ref.watch(adminP43RepositoryProvider).authStats(days));
final adminHealthProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP43RepositoryProvider).health());
final adminLaunchChecklistProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP43RepositoryProvider).launchChecklist());
final adminLegalListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(adminP43RepositoryProvider).legalList());