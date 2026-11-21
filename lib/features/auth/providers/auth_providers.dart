import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/data/supabase_auth_repository.dart';
import 'package:hb_social/features/auth/domain/auth_repository.dart';
import 'package:hb_social/features/auth/data/auth_security_repository.dart';
import 'package:hb_social/features/auth/domain/social_auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)));
final authSecurityRepositoryProvider = Provider<AuthSecurityRepository>((ref) => AuthSecurityRepository(ref.watch(supabaseClientProvider)));
final verifiedMfaFactorsProvider = FutureProvider<List<Factor>>((ref) => ref.watch(authSecurityRepositoryProvider).verifiedFactors());
final mfaChallengeRequiredProvider = FutureProvider<bool>((ref) => ref.watch(authSecurityRepositoryProvider).needsChallenge());

/// Emits the existing session immediately, then follows Supabase auth events.
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});

final authProfileStateProvider = FutureProvider<SocialAuthState?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return null;
  return ref.watch(authRepositoryProvider).myAuthState();
});

final myAuthIdentitiesProvider = FutureProvider.autoDispose<MyAuthIdentities>((ref) => ref.watch(authRepositoryProvider).myAuthIdentities());
