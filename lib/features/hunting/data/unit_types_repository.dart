import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitTypesRepository {
  final SupabaseClient _client;

  const UnitTypesRepository(this._client);

  Future<List<HuntingUnitTypeInfo>> forCountry(String countryCode) async {
    try {
      final rows = await _client.from('hunting_unit_types').select('country_code,code,name_key,sort_order').eq('country_code', countryCode).order('sort_order');
      return (rows as List).map((row) => HuntingUnitTypeInfo.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String?> typeForUnit(String? unitId) async {
    if (unitId == null) return null;
    try {
      final row = await _client.from('hunting_units').select('unit_type').eq('id', unitId).maybeSingle();
      return row?['unit_type'] as String?;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}