import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/admin/data/admin_console_repository.dart';
import 'package:hb_social/features/admin/data/empty_admin_console_repository.dart';
import 'package:hb_social/features/admin/domain/admin_moderation.dart';

final adminConsoleRepositoryProvider = Provider<AdminConsoleRepository>((ref) => const EmptyAdminConsoleRepository());
final adminUsersProvider = FutureProvider.autoDispose<List<AdminUserRecord>>((ref) => ref.watch(adminConsoleRepositoryProvider).users());
final adminReportsProvider = FutureProvider.autoDispose<List<AdminReportRecord>>((ref) => ref.watch(adminConsoleRepositoryProvider).reports());
final adminBadgeRequestsProvider = FutureProvider.autoDispose<List<AdminBadgeRequest>>((ref) => ref.watch(adminConsoleRepositoryProvider).badgeRequests());