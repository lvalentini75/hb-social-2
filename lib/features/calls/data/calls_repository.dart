import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/calls/domain/call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallsRepository {
  final SupabaseClient _client;
  const CallsRepository(this._client);
  SupabaseClient get client => _client;

  Future<AppCall> start(String calleeId, String kind) async => AppCall.fromJson(await _object('call_start', {'p_callee_id': calleeId, 'p_kind': kind}));
  Future<AppCall> answer(String id) async => AppCall.fromJson(await _object('call_answer', {'p_call_id': id}));
  Future<AppCall> decline(String id) async => AppCall.fromJson(await _object('call_decline', {'p_call_id': id}));
  Future<AppCall> cancel(String id) async => AppCall.fromJson(await _object('call_cancel', {'p_call_id': id}));
  Future<AppCall> detail(String id) async => AppCall.fromJson(await _object('call_detail', {'p_call_id': id}));
  Future<AppCall?> active() async { final raw = await _rpc('my_active_call', const {}); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return value is Map && value.isNotEmpty ? AppCall.fromJson(Map<String, dynamic>.from(value)) : null; }
  Future<List<AppCall>> history({int limit = 20, DateTime? beforeCreatedAt, String? beforeId}) async => [for (final row in await _maps('my_calls', {'p_limit': limit, 'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(), 'p_before_id': beforeId})) AppCall.fromJson(row)];
  Future<CallToken> token(String id) async => CallToken.fromJson(await _edge({'action': 'call_token', 'call_id': id}));
  Future<AppCall> end(String id, {String? reason}) async => AppCall.fromJson(await _edge({'action': 'end_call', 'call_id': id, 'reason': reason}));

  Future<Map<String, dynamic>> _edge(Map<String, dynamic> body) async { try { final response = await _client.functions.invoke('livekit', body: body, headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'}); final data = Map<String, dynamic>.from(response.data as Map? ?? const {}); if (data['error'] != null) throw AppException('calls.errors.${data['error']}'); return data; } catch (error) { throw _map(error); } }
  Future<List<Map<String, dynamic>>> _maps(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); return [for (final row in raw as List? ?? const []) Map<String, dynamic>.from(row as Map)]; }
  Future<Map<String, dynamic>> _object(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return Map<String, dynamic>.from(value as Map? ?? const {}); }
  Future<Object?> _rpc(String name, Map<String, dynamic> params) async { try { return await _client.rpc(name, params: params); } catch (error) { throw _map(error); } }
  AppException _map(Object error) { if (error is AppException) return error; final text = error.toString().toLowerCase(); for (final key in _callErrors) { if (text.contains(key)) return AppException('calls.errors.$key'); } return ErrorMapper.fromSupabase(error); }
}

const _callErrors = {'not_authenticated','account_suspended','feature_disabled','call_kind_invalid','call_target_invalid','call_not_allowed','call_already_active','call_rate_limited','call_not_found','call_not_ringing','call_not_active'};