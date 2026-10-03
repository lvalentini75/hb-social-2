/// Authentication status shown across the shell while there is no backend.
enum AuthStatus { unauthenticated, authenticated }

/// The current auth state read by the UI. Until Supabase is connected (P03)
/// this is always [AuthStatus.unauthenticated] — there is no session, no
/// demo user and no local sign-in simulation.
class AuthState {
  final AuthStatus status;

  const AuthState({required this.status});

  const AuthState.unauthenticated() : status = AuthStatus.unauthenticated;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
