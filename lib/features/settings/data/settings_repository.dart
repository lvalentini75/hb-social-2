import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/safety/domain/safety_user.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';

class UserSettingsRecord {
  final DateTime? birthDate;
  final DateTime? onboardingCompletedAt;
  final bool showSensitive;
  final String messagePolicy;
  final bool autoTranslate;

  const UserSettingsRecord({this.birthDate, this.onboardingCompletedAt, this.showSensitive = false, this.messagePolicy = 'everyone', this.autoTranslate = true});

  factory UserSettingsRecord.fromJson(Map<String, dynamic> json) => UserSettingsRecord(
    birthDate: _dateTime(json['birth_date']),
    onboardingCompletedAt: _dateTime(json['onboarding_completed_at']),
    showSensitive: json['show_sensitive'] as bool? ?? false,
    messagePolicy: json['message_policy'] as String? ?? 'everyone',
    autoTranslate: json['auto_translate'] as bool? ?? true,
  );
}

DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}

/// Persists the profile fields that drive localization and hunting context.
class SettingsRepository {
  final SupabaseClient _client;

  const SettingsRepository(this._client);

  Future<void> updateProfile(String userId, Map<String, dynamic> values) async {
    try {
      await _client.from('user_profiles').update(values).eq('id', userId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}

/// Own-only access to private settings stored outside the public profile.
class UserSettingsRepository {
  final SupabaseClient _client;

  const UserSettingsRepository(this._client);

  Future<UserSettingsRecord?> getMine() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final row = await _client.from('user_settings').select('birth_date,onboarding_completed_at,show_sensitive,message_policy,auto_translate').eq('user_id', userId).maybeSingle();
      return row == null ? null : UserSettingsRecord.fromJson(row);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> updateMine({DateTime? birthDate, DateTime? onboardingCompletedAt, bool? showSensitive, String? messagePolicy, bool? autoTranslate}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');
      final values = <String, dynamic>{};
      if (birthDate != null) values['birth_date'] = _dateOnly(birthDate);
      if (onboardingCompletedAt != null) values['onboarding_completed_at'] = onboardingCompletedAt.toUtc().toIso8601String();
      if (showSensitive != null) values['show_sensitive'] = showSensitive;
      if (messagePolicy != null) values['message_policy'] = messagePolicy;
      if (autoTranslate != null) values['auto_translate'] = autoTranslate;
      if (values.isNotEmpty) await _client.from('user_settings').update(values).eq('user_id', userId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<SafetyUser>> listBlocked() => _listSafetyUsers('list_blocked', 'blocked_at');
  Future<List<SafetyUser>> listMuted() => _listSafetyUsers('list_muted', 'muted_at');
  Future<void> unblockUser(String userId) => _safetyAction('unblock_user', userId);
  Future<void> unmuteUser(String userId) => _safetyAction('unmute_user', userId);

  Future<List<DataExportRecord>> myDataExports() async {
    try {
      final rows = await _client.rpc('my_data_exports');
      return [for (final raw in rows as List) DataExportRecord.fromJson(Map<String, dynamic>.from(raw as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> requestDataExport() => _rpc('request_my_data_export');

  Future<String> dataExportUrl(String id) async {
    try {
      final path = await _client.rpc('data_export_download', params: {'p_id': id});
      return storageSignedUrl(_client, 'gdpr-exports', path.toString(), expiresIn: 3600);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AccountDeletionStatus> accountDeletionStatus() async {
    try {
      final raw = await _client.rpc('my_account_deletion_status');
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      return AccountDeletionStatus.fromJson(Map<String, dynamic>.from(value as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AccountDeletionStatus> requestAccountDeletion() async {
    try {
      final raw = await _client.rpc('request_my_account_deletion');
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      final json = Map<String, dynamic>.from(value as Map);
      return AccountDeletionStatus(pending: true, eraseAfter: _dateTime(json['erase_after']));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> cancelAccountDeletion() => _rpc('cancel_my_account_deletion');

  Future<void> _rpc(String name) async {
    try { await _client.rpc(name); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<SafetyUser>> _listSafetyUsers(String function, String dateField) async {
    try {
      final rows = await _client.rpc(function);
      return (rows as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
        return SafetyUser.fromJson(json, dateField);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> _safetyAction(String function, String userId) async {
    try { await _client.rpc(function, params: {'p_user': userId}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  String _dateOnly(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}