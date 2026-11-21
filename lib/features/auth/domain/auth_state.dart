enum AuthStatus { unauthenticated, authenticated }

/// Authentication state derived from the current Supabase session.
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;

  const AuthState({required this.status, this.userId, this.email});

  const AuthState.unauthenticated() : status = AuthStatus.unauthenticated, userId = null, email = null;

  const AuthState.authenticated({required String this.userId, required this.email}) : status = AuthStatus.authenticated;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
