import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MfaEnrollment {
  final String factorId;
  final String secret;
  final String uri;
  final String qrCode;

  const MfaEnrollment({required this.factorId, required this.secret, required this.uri, required this.qrCode});
}

class AuthSecurityRepository {
  final SupabaseClient _client;

  const AuthSecurityRepository(this._client);

  Future<List<Factor>> verifiedFactors() async {
    try {
      final response = await _client.auth.mfa.listFactors();
      return response.totp.where((factor) => factor.status == FactorStatus.verified).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<MfaEnrollment> enroll() async {
    try {
      final response = await _client.auth.mfa.enroll(factorType: FactorType.totp, friendlyName: 'HB Social');
      final totp = response.totp;
      if (totp == null) throw const AppException('auth.errors.generic');
      return MfaEnrollment(factorId: response.id, secret: totp.secret, uri: totp.uri, qrCode: totp.qrCode);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> verify(String factorId, String code) async {
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);
      await _client.auth.mfa.verify(factorId: factorId, challengeId: challenge.id, code: code);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> unenroll(String factorId, String code) async {
    await verify(factorId, code);
    try {
      await _client.auth.mfa.unenroll(factorId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<bool> needsChallenge() async {
    try {
      final levels = await _client.auth.mfa.getAuthenticatorAssuranceLevel();
      return levels.currentLevel == AuthenticatorAssuranceLevels.aal1 && levels.nextLevel == AuthenticatorAssuranceLevels.aal2;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> challenge(String code) async {
    final factors = await verifiedFactors();
    if (factors.isEmpty) throw const AppException('errors.mfa_invalid_code');
    await verify(factors.first.id, code);
  }
}