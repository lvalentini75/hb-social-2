import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/admin/data/unauthenticated_admin_auth_repository.dart';
import 'package:hb_social/features/admin/domain/admin_auth_repository.dart';
import 'package:hb_social/features/admin/domain/admin_session.dart';

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) => const UnauthenticatedAdminAuthRepository());
final adminSessionProvider = Provider<AdminSession>((ref) => ref.watch(adminAuthRepositoryProvider).currentSession);