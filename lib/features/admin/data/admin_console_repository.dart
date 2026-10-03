import 'package:hb_social/features/admin/domain/admin_moderation.dart';

abstract class AdminConsoleRepository {
  Future<List<AdminUserRecord>> users();
  Future<List<AdminReportRecord>> reports();
  Future<List<AdminBadgeRequest>> badgeRequests();
}