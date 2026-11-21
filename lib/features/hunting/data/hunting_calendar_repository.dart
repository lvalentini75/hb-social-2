import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HuntingRepository {
  final SupabaseClient _client;

  const HuntingRepository(this._client);

  Future<String> dataVersion(String? regionId) async {
    try {
      final value = await _client.rpc('hunting_data_version', params: {'p_region_id': regionId});
      return value?.toString() ?? '';
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<CalendarDayInfo>> overview({required String regionId, required DateTime day, String? appliesTo, double? lat, double? lng}) async {
    try {
      final rows = await _client.rpc('calendar_overview', params: {'p_region_id': regionId, 'p_date': _dateOnly(day), 'p_applies_to': appliesTo, 'p_lat': lat, 'p_lng': lng});
      return (rows as List).map((row) => CalendarDayInfo.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<HuntingDayInfo> huntingDay({required String regionId, required String speciesId, required DateTime day, String? appliesTo, String? unitId, double? lat, double? lng}) async {
    try {
      final value = await _client.rpc('hunting_day', params: {'p_region_id': regionId, 'p_species_id': speciesId, 'p_date': _dateOnly(day), 'p_applies_to': appliesTo, 'p_unit_id': unitId, 'p_lat': lat, 'p_lng': lng});
      return HuntingDayInfo.fromJson(Map<String, dynamic>.from(value as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<RegionCalendars>> regionsWithCalendars(String? countryCode) async {
    try {
      final rows = await _client.rpc('regions_with_calendars', params: {'p_country': countryCode});
      return [for (final row in rows as List) RegionCalendars.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<CalendarChange>> nextChanges({required String regionId, required DateTime from, int days = 30}) async {
    try {
      final rows = await _client.rpc('next_changes', params: {'p_region_id': regionId, 'p_from': _dateOnly(from), 'p_days': days});
      return [for (final row in rows as List) CalendarChange.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<SunTimes> sunTimes({required DateTime day, required double lat, required double lng}) async {
    try {
      final raw = await _client.rpc('hb_sun_times', params: {'p_date': _dateOnly(day), 'p_lat': lat, 'p_lng': lng});
      final value = raw is List ? Map<String, dynamic>.from(raw.first as Map) : Map<String, dynamic>.from(raw as Map);
      return SunTimes(day: day, sunrise: DateTime.parse(value['sunrise'] as String), sunset: DateTime.parse(value['sunset'] as String));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  String _dateOnly(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}