import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHuntingRepository {
  final SupabaseClient _client;
  const AdminHuntingRepository(this._client);

  static const calendarSelect = '*,region:regions!hunting_calendars_region_id_fkey(name),hunting_unit:hunting_units!hunting_calendars_hunting_unit_id_fkey(name),publisher:user_profiles!hunting_calendars_published_by_fkey(display_name),species:species!inner(id,scientific_name,category,names:species_names(locale,name)),rules:calendar_rules(id,kind,date_from,date_to,allowed_days,time_rule,bag_limit,bag_period,notes,applies_to,sort_order)';

  Future<AdminHuntingReferenceData> references() async {
    try {
      final values = await Future.wait<dynamic>([
        _client.from('countries').select('code,name').eq('is_active', true).order('sort_order'),
        _client.from('regions').select('id,country_code,code,name,kind').order('name'),
        _client.from('hunting_unit_types').select().order('sort_order'),
        _client.from('species').select('id,scientific_name,category,names:species_names(locale,name)').order('scientific_name'),
      ]);
      return AdminHuntingReferenceData(countries: [for (final row in values[0] as List) AdminHuntingCountry.fromJson(Map<String, dynamic>.from(row as Map))], regions: [for (final row in values[1] as List) AdminHuntingRegion.fromJson(Map<String, dynamic>.from(row as Map))], unitTypes: [for (final row in values[2] as List) AdminHuntingUnitType.fromJson(Map<String, dynamic>.from(row as Map))], species: [for (final row in values[3] as List) SpeciesInfo.fromJson(Map<String, dynamic>.from(row as Map))]);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminCalendarRecord>> calendars({required String countryCode, String? regionId, String? season, String? status, String search = ''}) async {
    try {
      dynamic query = _client.from('hunting_calendars').select(calendarSelect).eq('country_code', countryCode);
      if (regionId != null) query = query.eq('region_id', regionId);
      if (season != null) query = query.eq('season_label', season);
      if (status != null) query = query.eq('status', status);
      final rows = await query.order('region_id').order('species_id').limit(500);
      final normalized = search.trim().toLowerCase();
      final items = [for (final row in rows as List) AdminCalendarRecord.fromJson(Map<String, dynamic>.from(row as Map))];
      items.sort((a, b) { final region = a.regionName.compareTo(b.regionName); if (region != 0) return region; final category = a.calendar.species.category.compareTo(b.calendar.species.category); return category != 0 ? category : a.calendar.species.nameFor('it').compareTo(b.calendar.species.nameFor('it')); });
      return normalized.isEmpty ? items : items.where((item) => item.calendar.species.nameFor('it').toLowerCase().contains(normalized) || item.calendar.species.scientificName.toLowerCase().contains(normalized)).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<AdminCalendarRecord?> calendar(String id) async {
    try { final row = await _client.from('hunting_calendars').select(calendarSelect).eq('id', id).maybeSingle(); return row == null ? null : AdminCalendarRecord.fromJson(Map<String, dynamic>.from(row)); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> saveCalendar({String? id, required Map<String, dynamic> values}) async {
    try {
      final result = await _client.rpc('admin_calendar_upsert', params: {'p_id': id, 'p_region_id': values['region_id'], 'p_hunting_unit_id': values['hunting_unit_id'], 'p_species_id': values['species_id'], 'p_season_label': values['season_label'], 'p_valid_from': values['valid_from'], 'p_valid_to': values['valid_to'], 'p_source_name': values['source_name'], 'p_source_url': values['source_url'], 'p_notes': values['notes']});
      return result.toString();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setCalendarStatus(String id, String status) async {
    try { await _client.rpc('admin_calendar_set_status', params: {'p_id': id, 'p_status': status}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteCalendar(String id) async { try { await _client.rpc('admin_calendar_set_status', params: {'p_id': id, 'p_status': 'archived'}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<int> duplicateSeason({required String regionId, required String fromSeason, required String toSeason}) async {
    try { final result = await _client.rpc('admin_calendar_clone_season', params: {'p_region_id': regionId, 'p_from_season': fromSeason, 'p_to_season': toSeason, 'p_hunting_unit_id': null}); return (result as Map?)?['created'] as int? ?? 0; } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Map<String, dynamic> _shiftRule(Map<String, dynamic> rule, String calendarId) { DateTime? shift(dynamic value) => value == null ? null : DateTime.parse(value as String).copyWith(year: DateTime.parse(value).year + 1); return {'calendar_id': calendarId, 'kind': rule['kind'], 'date_from': shift(rule['date_from'])?.toIso8601String().substring(0, 10), 'date_to': shift(rule['date_to'])?.toIso8601String().substring(0, 10), 'allowed_days': rule['allowed_days'], 'time_rule': rule['time_rule'], 'bag_limit': rule['bag_limit'], 'bag_period': rule['bag_period'], 'notes': rule['notes'], 'applies_to': rule['applies_to'], 'sort_order': rule['sort_order']}; }

  Future<void> saveRule({String? id, required Map<String, dynamic> values}) async { try { final current = await _client.from('calendar_rules').select().eq('calendar_id', values['calendar_id']).order('sort_order'); final rows = [for (final raw in current as List) Map<String, dynamic>.from(raw as Map)]; final index = rows.indexWhere((row) => row['id'] == id); final normalized = _ruleValues(values); if (index < 0) rows.add(normalized); else rows[index] = normalized; await _client.rpc('admin_calendar_rules_set', params: {'p_calendar_id': values['calendar_id'], 'p_rules': rows.map(_ruleValues).toList()}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> deleteRule(String id) async { try { final row = await _client.from('calendar_rules').select('calendar_id').eq('id', id).single(); final calendarId = row['calendar_id'] as String; final current = await _client.from('calendar_rules').select().eq('calendar_id', calendarId).neq('id', id).order('sort_order'); await _client.rpc('admin_calendar_rules_set', params: {'p_calendar_id': calendarId, 'p_rules': [for (final raw in current as List) _ruleValues(Map<String, dynamic>.from(raw as Map))]}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> reorderRules(List<CalendarRule> rules) async { if (rules.isEmpty) return; try { await _client.rpc('admin_calendar_rules_set', params: {'p_calendar_id': (await _client.from('calendar_rules').select('calendar_id').eq('id', rules.first.id).single())['calendar_id'], 'p_rules': [for (final rule in rules) {'kind': rule.kind, 'date_from': rule.dateFrom?.toIso8601String().substring(0, 10), 'date_to': rule.dateTo?.toIso8601String().substring(0, 10), 'allowed_days': rule.allowedDays, 'time_rule': rule.timeRule, 'bag_limit': rule.bagLimit, 'bag_period': rule.bagPeriod, 'applies_to': rule.appliesTo, 'notes': rule.notes}]}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Map<String, dynamic> _ruleValues(Map<String, dynamic> value) => {for (final key in const ['kind','date_from','date_to','allowed_days','time_rule','bag_limit','bag_period','applies_to','notes']) key: value[key]};
  Future<bool> calendarOpen(String calendarId, DateTime date, String? appliesTo) async { try { final value = await _client.rpc('admin_calendar_day', params: {'p_id': calendarId, 'p_date': date.toIso8601String().substring(0, 10), 'p_applies_to': appliesTo}); return (value as Map?)?['is_open'] == true; } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<List<AdminSpeciesRecord>> species() async { try { final items = await references(); final uses = await _client.from('hunting_calendars').select('species_id'); final counts = <String, int>{}; for (final row in uses as List) counts.update((row as Map)['species_id'] as String, (v) => v + 1, ifAbsent: () => 1); return [for (final item in items.species) AdminSpeciesRecord(species: item, publishedCalendarCount: counts[item.id] ?? 0)]; } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> saveSpecies({String? id, required String scientificName, required String category, required Map<String, String> names}) async { try { await _client.rpc('admin_species_upsert', params: {'p_id': id, 'p_scientific_name': scientificName, 'p_category': category, 'p_names': names, 'p_is_active': true, 'p_image_path': null}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> deleteSpecies(String id) async { try { await _client.rpc('admin_species_delete', params: {'p_id': id}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<List<AdminHuntingUnit>> units(String countryCode, {String? regionId, String? unitType}) async { try { dynamic query = _client.from('hunting_units').select('*,municipality:municipalities(name)').eq('country_code', countryCode); if (regionId != null) query = query.eq('region_id', regionId); if (unitType != null) query = query.eq('unit_type', unitType); final rows = await query.order('name').limit(500); return [for (final row in rows as List) AdminHuntingUnit.fromJson(Map<String, dynamic>.from(row as Map))]; } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> saveUnit({String? id, required Map<String, dynamic> values}) async { try { if (id == null) { await _client.from('hunting_units').insert(values); } else { await _client.from('hunting_units').update(values).eq('id', id); } await _client.from('hunting_units').select('id').eq('country_code', values['country_code']).eq('code', values['code']).limit(1); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<UnitUsage> unitUsage(String id) async { final values = await Future.wait([_client.from('user_profiles').count(CountOption.exact).eq('hunting_unit_id', id), _client.from('posts').count(CountOption.exact).eq('hunting_unit_id', id), _client.from('events').count(CountOption.exact).eq('hunting_unit_id', id), _client.from('hunting_calendars').count(CountOption.exact).eq('hunting_unit_id', id)]); return UnitUsage(profiles: values[0], posts: values[1], events: values[2], calendars: values[3]); }
  Future<void> deleteUnit(String id) async { final usage = await unitUsage(id); if (usage.total > 0) throw AppException('admin.hunting.errors.unit_used', namedArgs: {'count': '${usage.total}'}); try { await _client.from('hunting_units').delete().eq('id', id); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> importUnits(List<Map<String, dynamic>> rows) async { try { await _client.from('hunting_units').insert(rows); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<List<AdminUnitBoundary>> unitBoundaries(String countryCode, {String? regionId}) async {
    try {
      dynamic query = _client.from('hunting_unit_areas').select('unit_id,geojson,area_m2,source,updated_at,unit:hunting_units!inner(id,country_code,region_id,name,unit_type,code)').eq('unit.country_code', countryCode);
      if (regionId != null) query = query.eq('unit.region_id', regionId);
      final rows = await query.order('updated_at', ascending: false);
      return [for (final row in rows as List) AdminUnitBoundary.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setUnitBoundary({required String unitId, Map<String, dynamic>? geoJson, String? source}) async {
    try { await _client.rpc('set_unit_area', params: {'p_unit_id': unitId, 'p_geojson': geoJson, 'p_source': source?.trim().isEmpty == true ? null : source?.trim()}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminMunicipality>> searchMunicipalities(String query) async { try { final ids = await _client.rpc('search_municipalities', params: {'p_query': query, 'p_country': 'IT', 'p_region_id': null, 'p_limit': 50}); final idList = [for (final row in ids as List) (row as Map)['id'] as String]; if (idList.isEmpty) return const []; final rows = await _client.from('municipalities').select('*,region:regions(name)').inFilter('id', idList); return [for (final row in rows as List) AdminMunicipality.fromJson(Map<String, dynamic>.from(row as Map))]; } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> updateMunicipality(String id, Map<String, dynamic> values) async { try { await _client.from('municipalities').update(values).eq('id', id); await _client.from('municipalities').select('id').eq('id', id).single(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<List<AdminHuntingRegion>> regions(String countryCode) async { try { final raw = await _client.from('regions').select('id,country_code,code,name,kind').eq('country_code', countryCode).order('name'); final result = <AdminHuntingRegion>[]; for (final row in raw as List) { final id = (row as Map)['id'] as String; final counts = await Future.wait([_client.from('municipalities').count(CountOption.exact).eq('region_id', id), _client.from('hunting_calendars').count(CountOption.exact).eq('region_id', id)]); result.add(AdminHuntingRegion.fromJson(Map<String, dynamic>.from(row), municipalityCount: counts[0], calendarCount: counts[1])); } return result; } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> saveRegion({String? id, required Map<String, dynamic> values}) async { try { if (id == null) { await _client.from('regions').insert(values); } else { await _client.from('regions').update({'name': values['name']}).eq('id', id); } await _client.from('regions').select('id').eq('country_code', values['country_code']).eq('code', values['code']).limit(1); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
}