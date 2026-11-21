import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/map/domain/map_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapRepository {
  final SupabaseClient _client;
  final Map<String, ({DateTime at, MapOverview value})> _cache = {};
  final Map<String, OfficialLayerGeometry> _layerCache = {};
  MapRepository(this._client);

  Future<MapOverview> overview({required double lat, required double lng, required double radiusKm, bool force = false}) async {
    final key = '${(lat * 100).floor()}:${(lng * 100).floor()}:${radiusKm.round()}';
    final cached = _cache[key];
    if (!force && cached != null && DateTime.now().difference(cached.at) < const Duration(seconds: 60)) return cached.value;
    try {
      final result = await _client.rpc('map_overview', params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm, 'p_limit': 200});
      final value = MapOverview.fromJson(Map<String, dynamic>.from(result as Map));
      _cache[key] = (at: DateTime.now(), value: value);
      return value;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> upsertPoint({String? id, required String name, required MapPointKind kind, required double lat, required double lng, String? notes, String? color, required MapPointVisibility visibility}) async {
    try {
      final result = await _client.rpc('upsert_map_point', params: {'p_id': id, 'p_name': name.trim(), 'p_kind': kind.code, 'p_lat': lat, 'p_lng': lng, 'p_notes': notes?.trim().isEmpty == true ? null : notes?.trim(), 'p_color': color, 'p_visibility': visibility.code});
      _cache.clear();
      return result as String;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deletePoint(String id) async { try { await _client.rpc('delete_map_point', params: {'p_id': id}); _cache.clear(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<String> upsertZone({String? id, required String name, required List<List<double>> ring, String? notes, String? color, required MapPointVisibility visibility}) async {
    try {
      final result = await _client.rpc('upsert_map_zone', params: {'p_id': id, 'p_name': name.trim(), 'p_geojson': ring, 'p_notes': notes?.trim().isEmpty == true ? null : notes?.trim(), 'p_color': color, 'p_visibility': visibility.code});
      _cache.clear();
      return result as String;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteZone(String id) async { try { await _client.rpc('delete_map_zone', params: {'p_id': id}); _cache.clear(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<UnitAtPoint?> unitAt(double lat, double lng) async {
    try { final result = await _client.rpc('unit_at_point', params: {'p_lat': lat, 'p_lng': lng}); if (result == null) return null; final json = result is List ? result.cast<Object?>().firstOrNull : result; return json is Map && json.isNotEmpty ? UnitAtPoint.fromJson(Map<String, dynamic>.from(json)) : null; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<OfficialLayerGeometry> layerGeometry(OfficialMapLayer layer) async {
    final key = '${layer.id}:${layer.updatedAt.toIso8601String()}';
    final cached = _layerCache[key];
    if (cached != null) return cached;
    try {
      final value = await _client.rpc('map_layer_geojson', params: {'p_id': layer.id});
      final geometry = OfficialLayerGeometry.fromJson(Map<String, dynamic>.from(value as Map));
      _layerCache.removeWhere((cacheKey, _) => cacheKey.startsWith('${layer.id}:'));
      _layerCache[key] = geometry;
      return geometry;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
}