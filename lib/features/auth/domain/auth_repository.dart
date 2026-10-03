import 'package:hb_social/features/auth/domain/auth_state.dart';

/// Abstraction over the authentication backend. Until Supabase is connected
/// (P03) the only implementation is [UnauthenticatedAuthRepository].
abstract class AuthRepository {
  AuthState get currentState;
}
