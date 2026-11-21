import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/config/auth_config.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/auth/domain/auth_repository.dart';
import 'package:hb_social/features/auth/domain/social_auth_models.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  const SupabaseAuthRepository(this._client);

  static String? appleDisplayName;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  @override
  Future<void> signUp({required String username, required String displayName, required String email, required String password, required String countryCode, required String locale, required DateTime birthDate}) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim().toLowerCase(), 'display_name': displayName.trim(), 'country_code': countryCode, 'locale': locale, 'birth_date': _dateOnly(birthDate)},
      );
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  @override
  Future<void> requestPasswordReset(String email, String redirectTo) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  @override
  Future<bool> signInWithProvider(String provider, {required bool nativeApple}) async {
    try {
      if (provider == 'apple' && nativeApple && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final rawNonce = _client.auth.generateRawNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
        final credential = await SignInWithApple.getAppleIDCredential(scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce: hashedNonce);
        final name = [credential.givenName, credential.familyName].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
        if (name.isNotEmpty) appleDisplayName = name;
        if (credential.identityToken == null) throw const AppException('auth.generic');
        await _client.auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: credential.identityToken!, nonce: rawNonce);
        return true;
      }
      return _client.auth.signInWithOAuth(_provider(provider), redirectTo: AuthConfig.redirectUrl, authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return false;
      throw _authError(error);
    } catch (error) {
      throw _authError(error);
    }
  }

  @override
  Future<bool> linkProvider(String provider) async {
    try {
      return _client.auth.linkIdentity(_provider(provider), redirectTo: AuthConfig.redirectUrl, authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
    } catch (error) { throw _authError(error); }
  }

  @override
  Future<void> unlinkProvider(String identityId) async {
    try {
      final identities = await _client.auth.getUserIdentities();
      final identity = identities.firstWhere((item) => item.id == identityId);
      await _client.auth.unlinkIdentity(identity);
    } catch (error) { throw _authError(error); }
  }

  @override
  Future<List<UserIdentity>> userIdentities() async {
    try { return await _client.auth.getUserIdentities(); }
    catch (error) { throw _authError(error); }
  }

  @override
  Future<SocialAuthState> myAuthState() async => SocialAuthState.fromJson(await _objectRpc('my_auth_state'));

  @override
  Future<MyAuthIdentities> myAuthIdentities() async => MyAuthIdentities.fromJson(await _objectRpc('my_auth_identities'));

  @override
  Future<UsernameAvailability> usernameAvailable(String username) async => UsernameAvailability.fromJson(await _objectRpc('username_available', {'p_username': username.trim().toLowerCase()}));

  @override
  Future<SocialAuthState> completeProfile({DateTime? birthDate, String? countryCode, String? username, String? displayName, String? locale, String? regionId, String? avatarUrl}) async => SocialAuthState.fromJson(await _objectRpc('complete_profile', {
    'p_birth_date': birthDate == null ? null : _dateOnly(birthDate), 'p_country_code': countryCode, 'p_username': username?.trim().toLowerCase(), 'p_display_name': displayName?.trim(), 'p_locale': locale, 'p_region_id': regionId, 'p_avatar_url': avatarUrl,
  }));

  @override
  Future<void> updateEmail(String email) async {
    try { await _client.auth.updateUser(UserAttributes(email: email.trim())); }
    catch (error) { throw _authError(error); }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Map<String, dynamic>> _objectRpc(String name, [Map<String, dynamic> params = const {}]) async {
    try {
      final raw = await _client.rpc(name, params: params);
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      return Map<String, dynamic>.from(value as Map? ?? const {});
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  OAuthProvider _provider(String provider) => switch (provider) { 'google' => OAuthProvider.google, 'apple' => OAuthProvider.apple, 'facebook' => OAuthProvider.facebook, 'azure' => OAuthProvider.azure, _ => throw const AppException('auth.provider_unavailable') };

  AppException _authError(Object error) {
    if (error is AppException) return error;
    final message = error.toString().toLowerCase();
    if (message.contains('access_denied') || message.contains('canceled') || message.contains('cancelled') || message.contains('without code')) return const AppException('auth.cancelled');
    if (message.contains('unsupported provider') || message.contains('provider is not enabled')) return const AppException('auth.provider_unavailable');
    if (message.contains('identity_already_exists')) return const AppException('auth.identity_already_linked');
    if (message.contains('single_identity_not_deletable') || message.contains('manual_linking_disabled')) return const AppException('auth.cannot_unlink_last');
    if (message.contains('email_exists')) return const AppException('auth.email_in_use');
    return const AppException('auth.generic');
  }

  String _dateOnly(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}