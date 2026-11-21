import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_p43_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminP43Repository {
  final SupabaseClient _client;
  const AdminP43Repository(this._client);

  Future<List<AdminFeatureFlagRecord>> featureFlags() => _list('admin_feature_flags', const {}, AdminFeatureFlagRecord.fromJson);
  Future<AdminAuthStats> authStats(int days) async => AdminAuthStats.fromJson(await _object('admin_auth_stats', {'p_days': days}));
  Future<void> saveAuthSettings(Map<String, dynamic> value) => saveSetting('auth', value);
  Future<String> upsertFlag({String? country, required String module, required bool enabled, required int rollout, String? description}) async => (await _rpc('admin_feature_flag_upsert', {'p_module': module, 'p_country_code': country, 'p_is_enabled': enabled, 'p_rollout_percentage': rollout, 'p_description': _text(description)})).toString();
  Future<void> deleteFlag(String id) => _void('admin_feature_flag_delete', {'p_id': id});

  Future<List<AdminTranslationOverride>> translations({String? locale, String? query, int offset = 0}) => _list('admin_translations_list', {'p_locale': locale, 'p_q': _text(query), 'p_limit': 200, 'p_offset': offset}, AdminTranslationOverride.fromJson);
  Future<String> translationsVersion() async => (await _rpc('translations_version', const {})).toString();
  Future<void> upsertTranslation(String locale, String key, String value) => _void('admin_translation_upsert', {'p_locale': locale, 'p_key': key.trim(), 'p_value': value});
  Future<void> deleteTranslation(String locale, String key) => _void('admin_translation_delete', {'p_locale': locale, 'p_key': key});
  Future<Map<String, dynamic>> translationStats() => _object('admin_translation_stats', const {});
  Future<Map<String, dynamic>> deeplUsage() async {
    try {
      final response = await _client.functions.invoke('translate', body: {'action': 'usage'}, headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'});
      return Map<String, dynamic>.from(response.data as Map? ?? const {});
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminEmailTemplate>> emailTemplates() => _list('admin_email_templates', const {}, AdminEmailTemplate.fromJson);
  Future<void> saveEmail(AdminEmailTemplate item) => _void('admin_email_template_upsert', {'p_key': item.key, 'p_locale': item.locale, 'p_subject': item.subject, 'p_body_html': item.bodyHtml, 'p_body_text': item.bodyText, 'p_is_enabled': item.enabled});
  Future<Map<String, dynamic>> emailPreview(String key, String locale, Map<String, dynamic> variables) => _object('admin_email_preview', {'p_key': key, 'p_locale': locale, 'p_vars': variables});
  Future<String> testEmail(String key, String locale, Map<String, dynamic> variables) async => (await _rpc('admin_email_test_send', {'p_key': key, 'p_locale': locale, 'p_vars': variables})).toString();
  Future<List<Map<String, dynamic>>> emailOutbox({String? status, int offset = 0}) => _maps('admin_email_outbox', {'p_status': status, 'p_limit': 100, 'p_offset': offset});
  Future<Map<String, dynamic>> dispatchEmail() async {
    try {
      final response = await _client.functions.invoke('email-dispatch', body: {'limit': 50}, headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'});
      return Map<String, dynamic>.from(response.data as Map? ?? const {});
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<Map<String, dynamic>>> broadcasts({int offset = 0}) => _maps('admin_broadcasts_list', {'p_limit': 100, 'p_offset': offset});
  Future<Map<String, dynamic>> estimateBroadcast(Map<String, dynamic> audience) => _object('admin_broadcast_estimate', {'p_audience': audience});
  Future<String> saveBroadcast({String? id, required String name, required Map<String, dynamic> messages, String? route, required Map<String, dynamic> audience, DateTime? scheduledAt}) async => (await _rpc('admin_broadcast_upsert', {'p_id': id, 'p_name': name, 'p_messages': messages, 'p_route': _text(route), 'p_audience': audience, 'p_scheduled_at': scheduledAt?.toUtc().toIso8601String()})).toString();
  Future<Map<String, dynamic>> sendBroadcast(String id) => _object('admin_broadcast_send', {'p_id': id});
  Future<void> cancelBroadcast(String id) => _void('admin_broadcast_cancel', {'p_id': id});

  Future<List<AdminCronJob>> cronJobs() => _list('admin_cron_jobs', const {}, AdminCronJob.fromJson);
  Future<List<Map<String, dynamic>>> cronRuns(String name) => _maps('admin_cron_runs', {'p_jobname': name, 'p_limit': 100});
  Future<void> toggleCron(String name, bool active) => _void('admin_cron_toggle', {'p_jobname': name, 'p_active': active});
  Future<Map<String, dynamic>> runCron(String name) => _object('admin_cron_run_now', {'p_jobname': name});
  Future<void> saveSetting(String key, Map<String, dynamic> value) => _void('set_platform_setting', {'p_key': key, 'p_value': value});
  Future<Map<String, dynamic>?> setting(String key) async {
    try { final row = await _client.from('platform_settings').select('value').eq('key', key).maybeSingle(); return row == null ? null : Map<String, dynamic>.from(row['value'] as Map? ?? const {}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Map<String, dynamic>> health() => _object('hb_health', const {});
  Future<Map<String, dynamic>> launchChecklist() => _object('admin_launch_checklist', const {});
  Future<List<Map<String, dynamic>>> legalList() => _maps('admin_legal_list', const {});
  Future<List<Map<String, dynamic>>> legalDocuments(String kind, int version) => _maps('admin_legal_documents', {'p_kind': kind, 'p_version': version});
  Future<Map<String, dynamic>> legalUpsert({required String kind, required String locale, required String title, required String bodyMarkdown, String? summary, int? version}) => _object('admin_legal_upsert', {'p_kind': kind, 'p_locale': locale, 'p_title': title, 'p_body_md': bodyMarkdown, 'p_summary': _text(summary), 'p_version': version});
  Future<Map<String, dynamic>> legalPublish(String kind, int version) => _object('admin_legal_publish', {'p_kind': kind, 'p_version': version});
  Future<Map<String, dynamic>> legalConsents([String? kind]) => _object('admin_legal_consents', {'p_kind': kind});

  Future<List<AdminSupportTicket>> supportTickets({String status = 'open', String? category, String assigned = 'any', String? query, int offset = 0}) => _list('admin_support_tickets', {'p_status': status, 'p_category': category, 'p_assigned': assigned, 'p_q': _text(query), 'p_limit': 100, 'p_offset': offset}, AdminSupportTicket.fromJson);
  Future<Map<String, dynamic>> supportStats() => _object('admin_support_stats', const {});
  Future<List<Map<String, dynamic>>> supportMessages(String id) => _maps('support_ticket_messages', {'p_ticket_id': id});
  Future<String> supportReply(String id, String body, {required bool internal, bool close = false}) async => (await _rpc('admin_support_reply', {'p_ticket_id': id, 'p_body': body, 'p_internal': internal, 'p_attachments': const [], 'p_close': close})).toString();
  Future<void> supportStatus(String id, String status, String? priority) => _void('admin_support_set_status', {'p_ticket_id': id, 'p_status': status, 'p_priority': priority});
  Future<void> supportAssign(String id, String? adminId) => _void('admin_support_assign', {'p_ticket_id': id, 'p_admin_id': adminId});

  Future<List<T>> _list<T>(String name, Map<String, dynamic> params, T Function(Map<String, dynamic>) parser) async => [for (final row in await _maps(name, params)) parser(row)];
  Future<List<Map<String, dynamic>>> _maps(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); return [for (final row in raw as List? ?? const []) Map<String, dynamic>.from(row as Map)]; }
  Future<Map<String, dynamic>> _object(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return Map<String, dynamic>.from(value as Map? ?? const {}); }
  Future<void> _void(String name, Map<String, dynamic> params) async { await _rpc(name, params); }
  Future<Object?> _rpc(String name, Map<String, dynamic> params) async {
    try { return await _client.rpc(name, params: params); }
    catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('legal_locales_missing')) {
        final hint = error is PostgrestException ? error.hint : null;
        throw AppException('admin.legal.locales_missing', namedArgs: {'locales': hint ?? ''});
      }
      for (final key in _errors) { if (message.contains(key)) throw AppException('p43.errors.$key'); }
      throw ErrorMapper.fromSupabase(error);
    }
  }
  String? _text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}

const _errors = {'admin_permission_denied','admin_superadmin_required','settings_permission_denied','settings_value_invalid','flag_module_invalid','flag_rollout_invalid','flag_country_invalid','flag_not_found','flag_global_locked','translation_locale_invalid','translation_key_invalid','translation_value_invalid','translation_not_found','email_key_invalid','email_locale_invalid','email_content_invalid','email_template_not_found','broadcast_name_invalid','broadcast_messages_invalid','broadcast_route_invalid','broadcast_audience_invalid','broadcast_schedule_invalid','broadcast_locked','broadcast_not_found','cron_not_available','cron_job_not_found','cron_job_not_allowed','support_subject_invalid','support_category_invalid','support_body_invalid','support_attachments_invalid','support_too_many_open','support_ticket_exists','support_ticket_not_found','support_ticket_closed','support_status_invalid','support_priority_invalid','support_assignee_invalid','legal_kind_invalid','legal_locale_invalid','legal_content_invalid','legal_version_published','legal_version_not_found','account_suspended'};