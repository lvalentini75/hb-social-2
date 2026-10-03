import 'package:hb_social/features/admin/domain/admin_role.dart';

class AdminSession {
  final bool isAuthenticated;
  final String? displayName;
  final AdminRole? role;

  const AdminSession({required this.isAuthenticated, this.displayName, this.role});
  const AdminSession.unauthenticated() : isAuthenticated = false, displayName = null, role = null;
}