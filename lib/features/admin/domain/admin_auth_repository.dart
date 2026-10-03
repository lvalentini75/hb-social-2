import 'package:hb_social/features/admin/domain/admin_session.dart';

abstract class AdminAuthRepository {
  AdminSession get currentSession;
}