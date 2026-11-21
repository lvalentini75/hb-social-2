import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_live.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLiveRepository {
  final SupabaseClient _client;
  const AdminLiveRepository(this._client);
  Future<List<AdminLiveRecord>> list({String? status}) async {
    try { final raw = await _client.rpc('admin_live_list', params: {'p_status': status, 'p_limit': 100, 'p_offset': 0}); return [for (final row in raw as List? ?? const []) AdminLiveRecord.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<void> end(String id, String reason) async {
    try { await _client.rpc('admin_live_end', params: {'p_id': id, 'p_reason': reason.trim()}); }
    catch (error) { final text = error.toString().toLowerCase(); if (text.contains('admin_permission_denied')) throw const AppException('p43.errors.admin_permission_denied'); throw ErrorMapper.fromSupabase(error); }
  }
}