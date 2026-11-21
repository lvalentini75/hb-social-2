import 'dart:math';
import 'dart:typed_data';

import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/domain/sighting_alert.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SightingInput {
  final String? id;
  final String speciesId;
  final DateTime sightedAt;
  final int animalsCount;
  final SightingKind kind;
  final double? lat;
  final double? lng;
  final double? accuracyM;
  final String? municipalityId;
  final String? regionId;
  final String? notes;
  final SightingVisibility visibility;
  final String? mediaPath;
  final String? thumbnailPath;
  final String? logId;
  const SightingInput({this.id, required this.speciesId, required this.sightedAt, required this.animalsCount, required this.kind, this.lat, this.lng, this.accuracyM, this.municipalityId, this.regionId, this.notes, required this.visibility, this.mediaPath, this.thumbnailPath, this.logId});
}

class SightingPhotoUpload {
  final String path;
  final String thumbnailPath;
  const SightingPhotoUpload({required this.path, required this.thumbnailPath});
}

class SightingsRepository {
  final SupabaseClient _client;
  final MediaUploadService _media;
  const SightingsRepository(this._client, this._media);

  Future<List<Sighting>> mySightings({String? season, String? speciesId, String? logId, int limit = 20, int offset = 0}) => _list('my_sightings', {'p_season': season, 'p_species_id': speciesId, 'p_log_id': logId, 'p_limit': limit, 'p_offset': offset});
  Future<List<Sighting>> sightingsOf(String userId, {int limit = 20, int offset = 0}) => _list('sightings_of', {'p_user': userId, 'p_limit': limit, 'p_offset': offset});

  Future<List<SightingAlert>> myAlerts() async {
    try { final rows = await _client.rpc('my_sighting_alerts'); return [for (final row in rows as List) SightingAlert.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> upsertAlert(SightingAlertInput input) async {
    try { return await _client.rpc('upsert_sighting_alert', params: {'p_id': input.id, 'p_name': input.name, 'p_species_id': input.speciesId, 'p_kinds': [for (final kind in input.kinds) kind.code], 'p_lat': input.lat, 'p_lng': input.lng, 'p_radius_km': input.radiusKm, 'p_municipality_id': input.municipalityId, 'p_region_id': input.regionId, 'p_min_animals': input.minAnimals, 'p_cooldown_min': input.cooldownMin, 'p_is_active': input.isActive}) as String; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setAlertActive(String id, bool active) async {
    try { await _client.rpc('set_sighting_alert_active', params: {'p_id': id, 'p_active': active}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteAlert(String id) async {
    try { await _client.rpc('delete_sighting_alert', params: {'p_id': id}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<NearbySighting>> nearby({required double lat, required double lng, double radiusKm = 25, String? speciesId, DateTime? from, DateTime? to, int limit = 200}) async {
    try { final rows = await _client.rpc('sightings_nearby', params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm, 'p_species_id': speciesId, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String(), 'p_limit': limit}); return [for (final row in rows as List) NearbySighting.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<SightingHeatCell>> heatmap({required double lat, required double lng, required double radiusKm, String? speciesId, DateTime? from, DateTime? to}) async {
    try { final rows = await _client.rpc('sightings_heatmap', params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm, 'p_species_id': speciesId, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String()}); return [for (final row in rows as List) SightingHeatCell.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<SpeciesActivity>> speciesActivity({String? regionId, double? lat, double? lng, double radiusKm = 25, int days = 30, String? speciesId}) async {
    try { final rows = await _client.rpc('species_activity', params: {'p_region_id': regionId, 'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm, 'p_days': days, 'p_species_id': speciesId}); return [for (final row in rows as List) SpeciesActivity.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Uint8List?> downloadPhoto(String? path) async => path == null ? null : _client.storage.from('sighting-media').download(path);

  Future<List<Sighting>> _list(String rpc, Map<String, dynamic> params) async {
    try { final rows = await _client.rpc(rpc, params: params); return [for (final row in rows as List) Sighting.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<SightingDetail> detail(String id) async {
    try {
      final value = await _client.rpc('sighting_detail', params: {'p_id': id});
      if (value == null || value is List && value.isEmpty) throw const AppException('sightings.errors.not_found');
      final json = value is List ? Map<String, dynamic>.from(value.first as Map) : Map<String, dynamic>.from(value as Map);
      return SightingDetail.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> upsert(SightingInput input) async {
    try {
      return await _client.rpc('upsert_sighting', params: {'p_id': input.id, 'p_species_id': input.speciesId, 'p_sighted_at': input.sightedAt.toUtc().toIso8601String(), 'p_animals_count': input.animalsCount, 'p_kind': input.kind.code, 'p_lat': input.lat, 'p_lng': input.lng, 'p_accuracy_m': input.accuracyM, 'p_municipality_id': input.municipalityId, 'p_region_id': input.regionId, 'p_notes': input.notes, 'p_visibility': input.visibility.code, 'p_media_path': input.mediaPath, 'p_thumbnail_path': input.thumbnailPath, 'p_log_id': input.logId}) as String;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> delete(String id) async {
    try { final paths = (await _client.rpc('delete_sighting', params: {'p_id': id}) as List).cast<String>(); if (paths.isNotEmpty) await _client.storage.from('sighting-media').remove(paths); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<SightingPhotoUpload> uploadPhoto(Uint8List bytes, void Function(double) onProgress) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('errors.login_required');
    if (bytes.length > 15 * 1024 * 1024) throw const AppException('errors.file_too_large');
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const AppException('errors.image_processing_failed');
    final longest = max(decoded.width, decoded.height);
    final full = longest <= 1600 ? decoded : img.copyResize(decoded, width: decoded.width >= decoded.height ? 1600 : null, height: decoded.height > decoded.width ? 1600 : null, interpolation: img.Interpolation.average);
    final thumb = max(full.width, full.height) <= 400 ? full : img.copyResize(full, width: full.width >= full.height ? 400 : null, height: full.height > full.width ? 400 : null, interpolation: img.Interpolation.average);
    final id = const Uuid().v4();
    final path = '$userId/$id.jpg';
    final thumbnailPath = '$userId/${id}_t.jpg';
    await _media.uploadBytes(bucket: 'sighting-media', path: path, bytes: Uint8List.fromList(img.encodeJpg(full, quality: 85)), contentType: 'image/jpeg', onProgress: (value) => onProgress(value * 0.85));
    await _media.uploadBytes(bucket: 'sighting-media', path: thumbnailPath, bytes: Uint8List.fromList(img.encodeJpg(thumb, quality: 80)), contentType: 'image/jpeg', onProgress: (value) => onProgress(0.85 + value * 0.15));
    return SightingPhotoUpload(path: path, thumbnailPath: thumbnailPath);
  }

  String? publicUrl(String? path) => path == null ? null : _client.storage.from('sighting-media').getPublicUrl(path);
}