import 'package:hb_social/features/auth/domain/social_auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication operations exposed independently from Supabase UI types.
abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});

  Future<void> signUp({required String username, required String displayName, required String email, required String password, required String countryCode, required String locale, required DateTime birthDate});

  Future<void> requestPasswordReset(String email, String redirectTo);

  Future<void> updatePassword(String password);

  Future<bool> signInWithProvider(String provider, {required bool nativeApple});
  Future<bool> linkProvider(String provider);
  Future<void> unlinkProvider(String identityId);
  Future<SocialAuthState> myAuthState();
  Future<MyAuthIdentities> myAuthIdentities();
  Future<UsernameAvailability> usernameAvailable(String username);
  Future<SocialAuthState> completeProfile({DateTime? birthDate, String? countryCode, String? username, String? displayName, String? locale, String? regionId, String? avatarUrl});
  Future<void> updateEmail(String email);
  Future<List<UserIdentity>> userIdentities();

  Future<void> signOut();
}
