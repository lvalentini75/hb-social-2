import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/features/admin/data/admin_dashboard_repository.dart';
import 'package:hb_social/features/admin/domain/admin_dashboard.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) => AdminDashboardRepository(ref.watch(supabaseClientProvider)));

final adminDashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final access = await ref.watch(adminAccessProvider.future);
  if (access == null || !access.canRead('dashboard')) throw const AppException('errors.not_authorized');
  return ref.watch(adminDashboardRepositoryProvider).getDashboard();
});