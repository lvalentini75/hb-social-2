import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_repository.dart';
import 'package:hb_social/features/admin/domain/admin_access.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(supabaseClientProvider)));

final adminAccessProvider = FutureProvider<AdminAccess?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return null;
  return ref.watch(adminRepositoryProvider).getMyAccess();
});