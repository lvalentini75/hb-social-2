import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminP41Repository {
  final SupabaseClient _client;
  const AdminP41Repository(this._client);

  Future<List<AdminP41User>> users({String? query, String? status, String? country, String? verification, String? flag, DateTime? from, DateTime? to, String sort = 'created', int limit = 50, int offset = 0}) async {
    try {
      final rows = await _client.rpc('admin_users_list', params: {'p_q': _nullText(query), 'p_status': status, 'p_country': country, 'p_verification': verification, 'p_flag': flag, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String(), 'p_sort': sort, 'p_limit': limit, 'p_offset': offset});
      return [for (final raw in rows as List) AdminP41User.fromJson(Map<String, dynamic>.from(raw as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminUserP41Detail> userDetail(String id) async => _mappedRpc('admin_user_detail', {'p_user_id': id}, AdminUserP41Detail.fromJson);
  Future<Map<String, dynamic>> userIdentities(String id) async {
    try {
      final raw = await _client.rpc('admin_user_identities', params: {'p_user_id': id});
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      return Map<String, dynamic>.from(value as Map? ?? const {});
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<AdminModerationStats> stats() async => _mappedRpc('admin_moderation_stats', const {}, AdminModerationStats.fromJson);
  Future<void> addNote(String userId, String note) => _voidRpc('admin_user_note_add', {'p_user_id': userId, 'p_note': note.trim()});
  Future<void> deleteNote(String id) => _voidRpc('admin_user_note_delete', {'p_id': id});
  Future<void> suspend(String id, int? days, String reason, String? note) => _voidRpc('admin_user_suspend', {'p_user_id': id, 'p_days': days, 'p_reason': reason.trim(), 'p_note': _nullText(note)});
  Future<void> unsuspend(String id, String? note) => _voidRpc('admin_user_unsuspend', {'p_user_id': id, 'p_note': _nullText(note)});
  Future<void> ban(String id, String reason, String? note) => _voidRpc('admin_user_ban', {'p_user_id': id, 'p_reason': reason.trim(), 'p_note': _nullText(note)});
  Future<void> deleteUser(String id, String reason) => _voidRpc('admin_delete_user', {'p_user_id': id, 'p_reason': reason.trim()});
  Future<void> issueStrike(String id, String reason, String? details, int? days) => _voidRpc('issue_strike', {'p_user_id': id, 'p_reason': reason, 'p_details': _nullText(details), 'p_days': days});
  Future<void> revokeStrike(String id, String note) => _voidRpc('revoke_strike', {'p_id': id, 'p_note': note.trim()});
  Future<void> requestExport(String id) => _voidRpc('admin_request_data_export', {'p_user_id': id});
  Future<String> exportUrl(String id) async {
    try {
      final path = await _client.rpc('data_export_download', params: {'p_id': id});
      return storageSignedUrl(_client, 'gdpr-exports', path.toString(), expiresIn: 3600);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminReportQueueItem>> reports({String status = 'open', String? priority, String assigned = 'any', String? targetType, String? query, int limit = 50, int offset = 0}) async {
    try {
      final rows = await _client.rpc('admin_reports_queue', params: {'p_status': status, 'p_priority': priority, 'p_assigned': assigned, 'p_target_type': targetType, 'p_q': _nullText(query), 'p_limit': limit, 'p_offset': offset});
      return [for (final raw in rows as List) AdminReportQueueItem(Map<String, dynamic>.from(raw as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminReportP41Detail> reportDetail(String id) async => _mappedRpc('admin_report_detail', {'p_id': id}, AdminReportP41Detail.fromJson);
  Future<void> assignReport(String id, {String? adminId}) => _voidRpc('admin_report_assign', {'p_id': id, 'p_admin_id': adminId});
  Future<void> unassignReport(String id) => _voidRpc('admin_report_unassign', {'p_id': id});
  Future<ReportResolutionResult> resolveReport(String id, String action, {String? note, int? strikeDays, int? suspendDays}) => _mappedRpc('admin_report_resolve', {'p_id': id, 'p_action': action, 'p_note': _nullText(note), 'p_strike_days': strikeDays, 'p_suspend_days': suspendDays ?? 7}, ReportResolutionResult.fromJson);

  Future<Map<String, dynamic>> moderationSettings() async {
    try {
      final row = await _client.from('platform_settings').select('value').eq('key', 'moderation').maybeSingle();
      return row?['value'] is Map ? Map<String, dynamic>.from(row!['value'] as Map) : <String, dynamic>{};
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> saveModerationSettings(Map<String, dynamic> value) => _voidRpc('set_platform_setting', {'p_key': 'moderation', 'p_value': value});

  Future<T> _mappedRpc<T>(String name, Map<String, dynamic> params, T Function(Map<String, dynamic>) parse) async {
    try {
      final raw = await _client.rpc(name, params: params);
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      return parse(Map<String, dynamic>.from(value as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> _voidRpc(String name, Map<String, dynamic> params) async {
    try { await _client.rpc(name, params: params); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  String? _nullText(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}