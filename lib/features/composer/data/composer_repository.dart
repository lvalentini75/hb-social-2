import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComposerRepository {
  final SupabaseClient _client;

  const ComposerRepository(this._client);

  Future<String> createPost({required String kind, required String? content, required String visibility, required List<Map<String, dynamic>> media, required bool isSensitive, Map<String, dynamic>? poll, String? locationName, double? latitude, double? longitude, String? huntingUnitId, String? groupId, String? pageId}) async {
    try {
      final result = await _client.rpc('create_post', params: {
        'p_kind': kind,
        'p_content': content,
        'p_visibility': visibility,
        'p_media': media,
        'p_poll': poll,
        'p_location_name': locationName,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_hunting_unit_id': huntingUnitId,
        'p_is_sensitive': isSensitive,
        'p_group_id': groupId,
        'p_page_id': pageId,
      });
      return result as String;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String> createScheduledPost({required DateTime scheduledAt, required String kind, required String? content, required String visibility, required List<Map<String, dynamic>> media, required bool isSensitive, Map<String, dynamic>? poll, String? locationName, double? latitude, double? longitude, String? huntingUnitId, String? groupId, String? pageId}) async {
    try {
      final result = await _client.rpc('create_scheduled_post', params: {
        'p_scheduled_at': scheduledAt.toUtc().toIso8601String(), 'p_kind': kind, 'p_content': content,
        'p_visibility': visibility, 'p_media': media, 'p_poll': poll, 'p_location_name': locationName,
        'p_lat': latitude, 'p_lng': longitude, 'p_hunting_unit_id': huntingUnitId,
        'p_is_sensitive': isSensitive, 'p_group_id': groupId, 'p_page_id': pageId,
      });
      return result as String;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> updatePost(String id, String content) async {
    try {
      await _client.from('posts').update({'content': content.trim().isEmpty ? null : content.trim()}).eq('id', id);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _client.from('posts').delete().eq('id', id);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  String requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppException('errors.not_authenticated');
    return id;
  }
}