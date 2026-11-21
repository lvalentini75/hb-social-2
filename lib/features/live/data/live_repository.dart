import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/live/domain/live_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveRepository {
  final SupabaseClient _client;
  const LiveRepository(this._client);
  SupabaseClient get client => _client;

  Future<List<LiveStream>> active({String? country, int limit = 20}) async => [for (final row in await _maps('live_streams_active', {'p_country': country, 'p_limit': limit})) LiveStream.fromJson(row)];
  Future<LiveStream> detail(String id) async => LiveStream.fromJson(await _object('live_stream_detail', {'p_id': id}));
  Future<List<LiveStream>> mine({int limit = 50}) async => [for (final row in await _maps('my_live_streams', {'p_limit': limit})) LiveStream.fromJson(row)];
  Future<List<LiveMessage>> messages(String id, {int limit = 60, DateTime? before}) async => [for (final row in await _maps('live_messages_list', {'p_stream_id': id, 'p_limit': limit, 'p_before': before?.toUtc().toIso8601String()})) LiveMessage.fromJson(row)];
  Future<String> create({required String title, String? description, required String visibility, DateTime? scheduledAt, String? coverPath, required bool chatEnabled}) async => (await _rpc('live_create', {'p_title': title.trim(), 'p_description': _text(description), 'p_visibility': visibility, 'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(), 'p_cover_path': coverPath, 'p_chat_enabled': chatEnabled})).toString();
  Future<void> update(String id, {required String title, String? description, required String visibility, DateTime? scheduledAt, String? coverPath, required bool chatEnabled}) => _void('live_update', {'p_id': id, 'p_title': title.trim(), 'p_description': _text(description), 'p_visibility': visibility, 'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(), 'p_cover_path': coverPath, 'p_chat_enabled': chatEnabled});
  Future<Map<String, dynamic>> start(String id) => _object('live_start', {'p_id': id});
  Future<void> cancel(String id) => _void('live_cancel', {'p_id': id});
  Future<void> leave(String id) => _void('live_leave', {'p_id': id});
  Future<String> sendMessage(String id, String body) async => (await _rpc('live_send_message', {'p_stream_id': id, 'p_body': body.trim()})).toString();
  Future<void> moderate(String id, String userId, String action, {int minutes = 10}) => _void('live_moderate', {'p_stream_id': id, 'p_user_id': userId, 'p_action': action, 'p_minutes': minutes});
  Future<void> hideMessage(String id, bool hidden) => _void('live_hide_message', {'p_message_id': id, 'p_hidden': hidden});
  Future<void> pinMessage(String id, bool pinned) => _void('live_pin_message', {'p_message_id': id, 'p_pinned': pinned});
  Future<LiveToken> token(String id) async => LiveToken.fromJson(await _edge({'action': 'live_token', 'stream_id': id}));
  Future<Map<String, dynamic>> end(String id) => _edge({'action': 'end_live', 'stream_id': id});
  Future<void> kick(String id, String userId) async { await _edge({'action': 'live_kick', 'stream_id': id, 'user_id': userId}); }
  Future<List<Map<String, dynamic>>> viewers(String id) async {
    try { final rows = await _client.from('live_viewers').select('user_id,muted_until,joined_at,user:user_profiles!live_viewers_user_id_fkey(id,username,display_name,avatar_url)').eq('stream_id', id).isFilter('left_at', null); return [for (final row in rows as List) Map<String, dynamic>.from(row as Map)]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Map<String, dynamic>> _edge(Map<String, dynamic> body) async { try { final response = await _client.functions.invoke('livekit', body: body, headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'}); final data = Map<String, dynamic>.from(response.data as Map? ?? const {}); if (data['error'] != null) throw AppException('live.errors.${data['error']}'); return data; } catch (error) { throw _map(error); } }
  Future<List<Map<String, dynamic>>> _maps(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); return [for (final row in raw as List? ?? const []) Map<String, dynamic>.from(row as Map)]; }
  Future<Map<String, dynamic>> _object(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return Map<String, dynamic>.from(value as Map? ?? const {}); }
  Future<void> _void(String name, Map<String, dynamic> params) async { await _rpc(name, params); }
  Future<Object?> _rpc(String name, Map<String, dynamic> params) async { try { return await _client.rpc(name, params: params); } catch (error) { throw _map(error); } }
  AppException _map(Object error) { if (error is AppException) return error; final text = error.toString().toLowerCase(); for (final key in _liveErrors) { if (text.contains(key)) return AppException('live.errors.$key'); } return ErrorMapper.fromSupabase(error); }
  String? _text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}

const _liveErrors = {'not_authenticated','account_suspended','feature_disabled','live_title_invalid','live_description_invalid','live_visibility_invalid','live_schedule_invalid','live_cover_invalid','content_blocked','live_already_running','live_too_many_scheduled','live_not_found','live_locked','live_not_live','live_removed','live_muted','live_chat_disabled','live_message_invalid','live_too_fast','live_not_host','live_cannot_moderate_host','live_action_invalid','live_message_not_found'};