import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminP44Repository {
  final SupabaseClient _client;
  const AdminP44Repository(this._client);

  Future<AdminCalendarsStats> calendarStats(String? country) async => _guard(() async {
    final value = await _client.rpc('admin_calendars_stats', params: {'p_country': country});
    return AdminCalendarsStats.fromJson(_map(value));
  });

  Future<List<AdminCalendarRowP44>> calendars({String? country, String? regionId, String? season, String? status, String? speciesId, String? query, int limit = 200, int offset = 0}) async => _guard(() async {
    final value = await _client.rpc('admin_calendars_list', params: {'p_country': country, 'p_region_id': regionId, 'p_season': season, 'p_status': status, 'p_species_id': speciesId, 'p_q': _optional(query), 'p_limit': limit, 'p_offset': offset});
    return [for (final row in _rows(value)) AdminCalendarRowP44.fromJson(row)];
  });

  Future<String> upsertCalendar({String? id, required String regionId, String? huntingUnitId, required String speciesId, required String seasonLabel, required DateTime validFrom, required DateTime validTo, String? sourceName, String? sourceUrl, String? notes}) async => _guard(() async {
    final value = await _client.rpc('admin_calendar_upsert', params: {'p_id': id, 'p_region_id': regionId, 'p_hunting_unit_id': huntingUnitId, 'p_species_id': speciesId, 'p_season_label': seasonLabel, 'p_valid_from': _date(validFrom), 'p_valid_to': _date(validTo), 'p_source_name': _optional(sourceName), 'p_source_url': _optional(sourceUrl), 'p_notes': _optional(notes)});
    return value.toString();
  });

  Future<int> setRules(String calendarId, List<Map<String, dynamic>> rules) async => _guard(() async => (await _client.rpc('admin_calendar_rules_set', params: {'p_calendar_id': calendarId, 'p_rules': rules}) as num?)?.toInt() ?? 0);
  Future<CalendarValidation> validateCalendar(String id) async => _guard(() async => CalendarValidation.fromJson(_map(await _client.rpc('admin_calendar_validate', params: {'p_id': id}))));
  Future<Map<String, dynamic>> setCalendarStatus(String id, String status) async => _guard(() async => _map(await _client.rpc('admin_calendar_set_status', params: {'p_id': id, 'p_status': status})));
  Future<Map<String, dynamic>> bulkStatus({required String regionId, required String season, String fromStatus = 'draft', String toStatus = 'published'}) async => _guard(() async => _map(await _client.rpc('admin_calendars_bulk_status', params: {'p_region_id': regionId, 'p_season_label': season, 'p_from_status': fromStatus, 'p_to_status': toStatus})));
  Future<Map<String, dynamic>> cloneSeason({required String regionId, required String fromSeason, required String toSeason, String? huntingUnitId}) async => _guard(() async => _map(await _client.rpc('admin_calendar_clone_season', params: {'p_region_id': regionId, 'p_from_season': fromSeason, 'p_to_season': toSeason, 'p_hunting_unit_id': huntingUnitId})));
  Future<Map<String, dynamic>> importCalendars({required String regionId, required String season, required List<Map<String, dynamic>> rows}) async => _guard(() async => _map(await _client.rpc('admin_calendars_import', params: {'p_region_id': regionId, 'p_season_label': season, 'p_rows': rows})));
  Future<Map<String, dynamic>> calendarDay({required String id, required DateTime date, String? appliesTo}) async => _guard(() async => _map(await _client.rpc('admin_calendar_day', params: {'p_id': id, 'p_date': _date(date), 'p_applies_to': appliesTo})));

  Future<List<AdminSpeciesP44>> species({String? query, String? category, int limit = 200, int offset = 0}) async => _guard(() async {
    final value = await _client.rpc('admin_species_list', params: {'p_q': _optional(query), 'p_category': category, 'p_limit': limit, 'p_offset': offset});
    return [for (final row in _rows(value)) AdminSpeciesP44.fromJson(row)];
  });

  Future<String> upsertSpecies({String? id, required String scientificName, required String category, required Map<String, String> names, required bool isActive, String? imagePath}) async => _guard(() async => (await _client.rpc('admin_species_upsert', params: {'p_id': id, 'p_scientific_name': scientificName, 'p_category': category, 'p_names': names, 'p_is_active': isActive, 'p_image_path': imagePath})).toString());
  Future<Map<String, dynamic>> mergeSpecies(String fromId, String intoId) async => _guard(() async => _map(await _client.rpc('admin_species_merge', params: {'p_from_id': fromId, 'p_into_id': intoId})));
  Future<void> deleteSpecies(String id) async => _guard(() async { await _client.rpc('admin_species_delete', params: {'p_id': id}); });

  Future<List<AdminMapLayerP44>> mapLayers({String? country, String? regionId, String? status}) async => _guard(() async {
    final value = await _client.rpc('admin_map_layers', params: {'p_country': country, 'p_region_id': regionId, 'p_status': status});
    return [for (final row in _rows(value)) AdminMapLayerP44.fromJson(row)];
  });

  Future<String> upsertMapLayer({String? id, String? countryCode, String? regionId, required String kind, required String name, String? description, String? color, String? sourceName, String? sourceUrl, DateTime? validFrom, DateTime? validTo}) async => _guard(() async => (await _client.rpc('admin_map_layer_upsert', params: {'p_id': id, 'p_country_code': countryCode, 'p_region_id': regionId, 'p_kind': kind, 'p_name': name, 'p_description': _optional(description), 'p_color': color, 'p_source_name': _optional(sourceName), 'p_source_url': _optional(sourceUrl), 'p_valid_from': validFrom == null ? null : _date(validFrom), 'p_valid_to': validTo == null ? null : _date(validTo)})).toString());
  Future<Map<String, dynamic>> setMapLayerGeoJson(String id, Map<String, dynamic>? geoJson) async => _guard(() async => _map(await _client.rpc('admin_map_layer_set_geojson', params: {'p_id': id, 'p_geojson': geoJson})));
  Future<void> setMapLayerStatus(String id, String status) async => _guard(() async { await _client.rpc('admin_map_layer_set_status', params: {'p_id': id, 'p_status': status}); });
  Future<void> deleteMapLayer(String id) async => _guard(() async { await _client.rpc('admin_map_layer_delete', params: {'p_id': id}); });
  Future<Map<String, dynamic>> importUnitAreas({required String regionId, required String unitType, required Map<String, dynamic> featureCollection, required String codeProperty, required String nameProperty, String? source}) async => _guard(() async => _map(await _client.rpc('admin_import_unit_areas', params: {'p_region_id': regionId, 'p_unit_type': unitType, 'p_featurecollection': featureCollection, 'p_code_property': codeProperty, 'p_name_property': nameProperty, 'p_source': _optional(source)})));

  Future<T> _guard<T>(Future<T> Function() action) async { try { return await action(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Map<String, dynamic> _map(Object? value) { final raw = value is List ? value.firstOrNull : value; return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{}; }
  List<Map<String, dynamic>> _rows(Object? value) { if (value is List) return [for (final row in value) if (row is Map) Map<String, dynamic>.from(row)]; final map = _map(value); final rows = map['rows'] ?? map['items']; return [for (final row in rows as List? ?? const []) if (row is Map) Map<String, dynamic>.from(row)]; }
  String? _optional(String? value) => value?.trim().isEmpty == true ? null : value?.trim();
  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
}