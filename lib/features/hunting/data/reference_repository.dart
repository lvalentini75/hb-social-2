import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReferenceCountry {
  final String code;
  final String name;
  final String defaultLocale;
  final String defaultCurrency;
  final String unitSystem;
  final String nativeName;
  final String flag;
  final String? timezone;
  final bool hasRegions;
  final bool hasCalendars;

  const ReferenceCountry({required this.code, required this.name, required this.defaultLocale, required this.defaultCurrency, required this.unitSystem, required this.nativeName, required this.flag, this.timezone, required this.hasRegions, required this.hasCalendars});

  factory ReferenceCountry.fromJson(Map<String, dynamic> json) => ReferenceCountry(code: json['code'].toString().trim(), name: json['name']?.toString() ?? '', defaultLocale: json['default_locale']?.toString() ?? 'en', defaultCurrency: json['default_currency']?.toString().trim() ?? 'EUR', unitSystem: json['unit_system']?.toString() ?? 'metric', nativeName: json['native_name']?.toString() ?? '', flag: json['flag']?.toString() ?? '', timezone: json['timezone']?.toString(), hasRegions: json['has_regions'] == true, hasCalendars: json['has_calendars'] == true);
}

class ReferenceRegion {
  final String id;
  final String name;
  final String kind;
  final double? lat;
  final double? lng;

  const ReferenceRegion({required this.id, required this.name, required this.kind, this.lat, this.lng});

  factory ReferenceRegion.fromJson(Map<String, dynamic> json) => ReferenceRegion(id: json['id'] as String, name: json['name'] as String, kind: json['kind'] as String? ?? 'region', lat: (json['lat'] as num?)?.toDouble(), lng: (json['lng'] as num?)?.toDouble());
}

class Municipality {
  final String id;
  final String name;
  final String? nameAlt;
  final String? provinceCode;
  final String? provinceName;
  final String regionId;
  final String regionName;
  final String? istatCode;
  final double? lat;
  final double? lng;

  const Municipality({required this.id, required this.name, this.nameAlt, this.provinceCode, this.provinceName, required this.regionId, required this.regionName, this.istatCode, this.lat, this.lng});

  factory Municipality.fromJson(Map<String, dynamic> json) => Municipality(id: json['id'] as String, name: json['name'] as String, nameAlt: json['name_alt'] as String?, provinceCode: json['province_code'] as String?, provinceName: json['province_name'] as String?, regionId: json['region_id'] as String, regionName: json['region_name'] as String? ?? '', istatCode: json['istat_code'] as String?, lat: (json['lat'] as num?)?.toDouble(), lng: (json['lng'] as num?)?.toDouble());

  String get compactName => provinceCode == null ? name : '$name ($provinceCode)';
}

class ReferenceCurrency {
  final String code;
  final String name;
  final String symbol;
  final int minorUnits;
  final DateTime? rateValidOn;

  const ReferenceCurrency({required this.code, required this.name, required this.symbol, required this.minorUnits, this.rateValidOn});

  factory ReferenceCurrency.fromJson(Map<String, dynamic> json) => ReferenceCurrency(code: json['code'].toString().trim(), name: json['name']?.toString() ?? '', symbol: json['symbol']?.toString() ?? '', minorUnits: (json['minor_units'] as num?)?.toInt() ?? 2, rateValidOn: json['rate_valid_on'] == null ? null : DateTime.tryParse(json['rate_valid_on'].toString()));

  bool get isAvailable => rateValidOn != null;
}

/// Reads shared country and regional reference data seeded in Supabase.
class ReferenceRepository {
  final SupabaseClient _client;

  const ReferenceRepository(this._client);

  static final Map<String, List<ReferenceCountry>> _countriesByLocale = {};

  Future<List<ReferenceCountry>> getCountries(String locale) async {
    try {
      final cached = _countriesByLocale[locale];
      if (cached != null) return cached;
      final rows = await _client.rpc('countries_list', params: {'p_locale': locale});
      final countries = [for (final row in rows as List) ReferenceCountry.fromJson(Map<String, dynamic>.from(row as Map))];
      _countriesByLocale[locale] = countries;
      return countries;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<ReferenceRegion>> getRegions(String countryCode) async {
    try {
      final rows = await _client.from('regions').select('id,name,kind,lat,lng').eq('country_code', countryCode).order('sort_order');
      return (rows as List).cast<Map<String, dynamic>>().map(ReferenceRegion.fromJson).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<ReferenceCurrency>> getCurrencies() async {
    try {
      final rows = await _client.rpc('currencies_list');
      return [for (final row in rows as List) ReferenceCurrency.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<Species>> getSpecies(String locale) async {
    try {
      final rows = await _client.from('species').select('id,scientific_name,category,names:species_names(locale,name)').order('scientific_name');
      return (rows as List).map((row) => Species.fromJson(Map<String, dynamic>.from(row as Map), locale)).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<HuntingUnit>> getHuntingUnits(String regionId) async {
    try {
      final rows = await _client.from('hunting_units').select('id,name,unit_type,code').eq('region_id', regionId).order('name');
      return (rows as List).map((row) => HuntingUnit.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<Municipality>> searchMunicipalities(String query, {required String countryCode, String? regionId}) async {
    try {
      final rows = await _client.rpc('search_municipalities', params: {'p_query': query, 'p_country': countryCode, 'p_region_id': regionId, 'p_limit': 20});
      return (rows as List).map((row) => Municipality.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Municipality?> getMunicipality(String id) async {
    try {
      final row = await _client.from('municipalities').select('id,name,name_alt,province_code,province_name,region_id,istat_code,lat,lng').eq('id', id).maybeSingle();
      if (row == null) return null;
      final json = Map<String, dynamic>.from(row);
      final region = await _client.from('regions').select('name').eq('id', json['region_id']).maybeSingle();
      json['region_name'] = region?['name'];
      return Municipality.fromJson(json);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Map<String, String>> getSpeciesNames(String locale) async {
    try {
      final rows = await _client.from('species_names').select('species_id,name').eq('locale', locale);
      return {for (final row in rows as List) row['species_id'] as String: row['name'] as String};
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}