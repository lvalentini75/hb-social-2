import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_p42_repository.dart';
import 'package:hb_social/features/admin/domain/admin_p42_models.dart';

final adminP42RepositoryProvider = Provider<AdminP42Repository>((ref) => AdminP42Repository(ref.watch(supabaseClientProvider)));
final adminListingsStatsP42Provider = FutureProvider.autoDispose<AdminListingsStats>((ref) => ref.watch(adminP42RepositoryProvider).listingStats());
final adminOrdersStatsP42Provider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(adminP42RepositoryProvider).orderStats());
final adminPromoCodesProvider = FutureProvider.autoDispose<List<AdminPromoCode>>((ref) => ref.watch(adminP42RepositoryProvider).promoCodes());

class AdminRevenueRequest {
  final DateTime from;
  final DateTime to;
  final String group;
  const AdminRevenueRequest(this.from, this.to, this.group);
  @override bool operator ==(Object other) => other is AdminRevenueRequest && other.from == from && other.to == to && other.group == group;
  @override int get hashCode => Object.hash(from, to, group);
}
final adminRevenueProvider = FutureProvider.autoDispose.family<AdminRevenueReport, AdminRevenueRequest>((ref, request) => ref.watch(adminP42RepositoryProvider).revenue(request.from, request.to, request.group));