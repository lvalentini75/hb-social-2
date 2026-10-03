import 'package:hb_social/features/admin/data/admin_console_repository.dart';
import 'package:hb_social/features/admin/domain/admin_moderation.dart';

/// Visual-phase repository. P05 replaces this with real Supabase reads.
class EmptyAdminConsoleRepository implements AdminConsoleRepository {
  const EmptyAdminConsoleRepository();

  @override
  Future<List<AdminUserRecord>> users() async => const [];

  @override
  Future<List<AdminReportRecord>> reports() async => const [];

  @override
  Future<List<AdminBadgeRequest>> badgeRequests() async => const [];
}