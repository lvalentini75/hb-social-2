import 'package:hb_social/features/admin/domain/admin_auth_repository.dart';
import 'package:hb_social/features/admin/domain/admin_session.dart';

class UnauthenticatedAdminAuthRepository implements AdminAuthRepository {
  const UnauthenticatedAdminAuthRepository();

  @override
  AdminSession get currentSession => const AdminSession.unauthenticated();
}