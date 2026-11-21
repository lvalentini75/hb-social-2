import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_p41_repository.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';

final adminP41RepositoryProvider = Provider<AdminP41Repository>((ref) => AdminP41Repository(ref.watch(supabaseClientProvider)));
final adminModerationStatsProvider = FutureProvider.autoDispose<AdminModerationStats>((ref) => ref.watch(adminP41RepositoryProvider).stats());
final adminP41UserDetailProvider = FutureProvider.autoDispose.family<AdminUserP41Detail, String>((ref, id) => ref.watch(adminP41RepositoryProvider).userDetail(id));
final adminP41ReportDetailProvider = FutureProvider.autoDispose.family<AdminReportP41Detail, String>((ref, id) => ref.watch(adminP41RepositoryProvider).reportDetail(id));
final adminModerationSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP41RepositoryProvider).moderationSettings());
final adminUserIdentitiesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) => ref.watch(adminP41RepositoryProvider).userIdentities(id));