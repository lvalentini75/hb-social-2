import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/auth/data/unauthenticated_auth_repository.dart';
import 'package:hb_social/features/auth/domain/auth_repository.dart';
import 'package:hb_social/features/auth/domain/auth_state.dart';

/// Swap this override in `main.dart` once a real backend (Supabase, P03) is
/// connected. For now the only implementation is [UnauthenticatedAuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) => const UnauthenticatedAuthRepository());

/// The auth state read by the whole app (shell avatar, Profile page, ...).
final authStateProvider = Provider<AuthState>((ref) => ref.watch(authRepositoryProvider).currentState);
