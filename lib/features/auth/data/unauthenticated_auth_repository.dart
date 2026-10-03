import 'package:hb_social/features/auth/domain/auth_repository.dart';
import 'package:hb_social/features/auth/domain/auth_state.dart';

/// The only [AuthRepository] implementation during the visual phase (P01).
/// There is no backend, no session storage and no demo/fake user: every
/// screen always sees [AuthStatus.unauthenticated]. This will be replaced by
/// a Supabase-backed repository in P03.
class UnauthenticatedAuthRepository implements AuthRepository {
  const UnauthenticatedAuthRepository();

  @override
  AuthState get currentState => const AuthState.unauthenticated();
}
