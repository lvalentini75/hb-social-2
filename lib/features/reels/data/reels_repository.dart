import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/tus_uploader.dart';
import 'package:hb_social/features/reels/domain/reel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReelsRepository {
  final SupabaseClient _client;
  final Dio _dio;
  ReelsRepository(this._client) : _dio = Dio();
  SupabaseClient get client => _client;
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<ReelUploadGrant> createUpload() async => ReelUploadGrant.fromJson(await _edge({'action': 'create_upload'}));

  Future<void> uploadTus({required Map<String, dynamic> tus, required Uint8List bytes, required String fileName, required String mimeType, required ValueChanged<double> onProgress, CancelToken? cancelToken}) async { await TusUploader(_dio).upload(config: TusUploadConfig.fromJson(tus), bytes: bytes, fileName: fileName, mimeType: mimeType, onProgress: onProgress, cancelToken: cancelToken); }

  Future<Map<String, dynamic>> submit({required String videoId, required String caption, required bool isSensitive, String? locationName, double? latitude, double? longitude, String? huntingUnitId}) => _objectRpc('reel_submit', {'p_video_id': videoId, 'p_caption': caption.trim(), 'p_is_sensitive': isSensitive, 'p_location_name': _text(locationName), 'p_lat': latitude, 'p_lng': longitude, 'p_hunting_unit_id': huntingUnitId});

  Future<ReelVideo> refresh(String videoId) async => ReelVideo.fromJson(await _edge({'action': 'refresh', 'video_id': videoId}));
  Future<List<ReelVideo>> myVideos({int limit = 50}) async => [for (final row in await _listRpc('my_reel_videos', {'p_limit': limit})) ReelVideo.fromJson(row)];
  Future<void> discard(String videoId) => _rpc('discard_reel_video', {'p_video_id': videoId});
  Future<ReelUploadAllowance> uploadAllowed() async => ReelUploadAllowance.fromJson(await _objectRpc('reel_upload_allowed', const {}));

  Future<List<Reel>> feed({String? country, int limit = 20, DateTime? beforeCreatedAt, String? beforeId, bool seen = false}) async => _reels('reels_feed', {'p_country': country, 'p_limit': limit.clamp(1, 30), 'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(), 'p_before_id': beforeId, 'p_seen': seen});
  Future<List<Reel>> byUser(String userId, {int limit = 30, DateTime? beforeCreatedAt, String? beforeId}) async => _reels('reels_by_user', {'p_user_id': userId, 'p_limit': limit, 'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(), 'p_before_id': beforeId});
  Future<Reel> detail(String postId) async => Reel.fromJson(await _objectRpc('reel_detail', {'p_post_id': postId}));
  Future<void> recordView(String postId, int watchedMs, bool completed) => _rpc('record_reel_view', {'p_post_id': postId, 'p_watched_ms': watchedMs, 'p_completed': completed});
  Future<ReelInsights> insights(String postId) async => ReelInsights.fromJson(await _objectRpc('reel_insights', {'p_post_id': postId}));
  Future<Map<String, dynamic>> adminStats() => _objectRpc('admin_reels_stats', const {});

  Future<Map<String, ReelVideo>> videosForPosts(List<String> postIds) async {
    if (postIds.isEmpty) return const {};
    try {
      final rows = await _client.from('reel_videos').select('id,status,post_id,caption,thumbnail_url,duration_s,error,submitted_at,created_at,ready_at,view_count').inFilter('post_id', postIds).eq('status', 'ready');
      return {for (final raw in rows as List) if (raw['post_id'] != null) raw['post_id'].toString(): ReelVideo.fromJson(Map<String, dynamic>.from(raw as Map))};
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<Reel>> _reels(String name, Map<String, dynamic> params) async => [for (final row in await _listRpc(name, params)) Reel.fromJson(row)];
  Future<List<Map<String, dynamic>>> _listRpc(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); return [for (final row in raw as List? ?? const []) Map<String, dynamic>.from(row as Map)]; }
  Future<Map<String, dynamic>> _objectRpc(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return Map<String, dynamic>.from(value as Map? ?? const {}); }
  Future<Object?> _rpc(String name, Map<String, dynamic> params) async { try { return await _client.rpc(name, params: params); } catch (error) { throw _map(error); } }
  Future<Map<String, dynamic>> _edge(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke('reels', body: body, headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'});
      final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
      if (data['error'] != null) throw AppException('reels.errors.${data['error']}');
      return data;
    } catch (error) { throw _map(error); }
  }
  AppException _map(Object error) {
    if (error is AppException) return error;
    final text = error.toString().toLowerCase();
    for (final key in _errorKeys) { if (text.contains(key)) return AppException('reels.errors.$key'); }
    return ErrorMapper.fromSupabase(error);
  }
  String? _text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}

const _errorKeys = {'not_authenticated','account_suspended','feature_disabled','reel_daily_limit','reel_not_found','reel_video_unavailable','reel_already_published','reel_too_long','post_content_too_long','post_unit_invalid','post_not_found','post_not_author','post_kind_invalid'};