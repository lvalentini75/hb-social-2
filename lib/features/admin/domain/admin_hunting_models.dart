import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';

class AdminHuntingReferenceData {
  final List<AdminHuntingCountry> countries;
  final List<AdminHuntingRegion> regions;
  final List<AdminHuntingUnitType> unitTypes;
  final List<SpeciesInfo> species;

  const AdminHuntingReferenceData({required this.countries, required this.regions, required this.unitTypes, required this.species});
}

class AdminHuntingCountry {
  final String code;
  final String name;
  const AdminHuntingCountry({required this.code, required this.name});
  factory AdminHuntingCountry.fromJson(Map<String, dynamic> json) => AdminHuntingCountry(code: (json['code'] as String).trim(), name: json['name'] as String);
}

class AdminHuntingRegion {
  final String id;
  final String countryCode;
  final String code;
  final String name;
  final String kind;
  final int municipalityCount;
  final int calendarCount;

  const AdminHuntingRegion({required this.id, required this.countryCode, required this.code, required this.name, required this.kind, this.municipalityCount = 0, this.calendarCount = 0});
  factory AdminHuntingRegion.fromJson(Map<String, dynamic> json, {int municipalityCount = 0, int calendarCount = 0}) => AdminHuntingRegion(id: json['id'] as String, countryCode: (json['country_code'] as String).trim(), code: json['code'] as String? ?? '', name: json['name'] as String, kind: json['kind'] as String? ?? 'region', municipalityCount: municipalityCount, calendarCount: calendarCount);
}

class AdminHuntingUnitType {
  final String countryCode;
  final String code;
  final Map<String, String> labels;
  const AdminHuntingUnitType({required this.countryCode, required this.code, required this.labels});
  factory AdminHuntingUnitType.fromJson(Map<String, dynamic> json) {
    final labels = <String, String>{};
    final raw = json['labels'];
    if (raw is Map) for (final entry in raw.entries) labels[entry.key.toString()] = entry.value.toString();
    for (final locale in const ['it', 'en', 'fr', 'es', 'de']) if (json['label_$locale'] != null) labels[locale] = json['label_$locale'] as String;
    return AdminHuntingUnitType(countryCode: (json['country_code'] as String).trim(), code: json['code'] as String, labels: labels);
  }
  String label(String locale) => labels[locale] ?? labels['it'] ?? code.toUpperCase();
}

class AdminHuntingUnit {
  final String id;
  final String countryCode;
  final String regionId;
  final String unitType;
  final String code;
  final String name;
  final String? municipalityId;
  final String? municipalityName;
  final String? website;
  final String? notes;

  const AdminHuntingUnit({required this.id, required this.countryCode, required this.regionId, required this.unitType, required this.code, required this.name, this.municipalityId, this.municipalityName, this.website, this.notes});
  factory AdminHuntingUnit.fromJson(Map<String, dynamic> json) => AdminHuntingUnit(id: json['id'] as String, countryCode: (json['country_code'] as String).trim(), regionId: json['region_id'] as String, unitType: json['unit_type'] as String, code: json['code'] as String? ?? '', name: json['name'] as String, municipalityId: json['municipality_id'] as String?, municipalityName: (json['municipality'] as Map?)?['name'] as String?, website: json['website'] as String?, notes: json['notes'] as String?);
}

class AdminMunicipality {
  final String id;
  final String name;
  final String? nameAlt;
  final String? provinceCode;
  final String? provinceName;
  final String regionId;
  final String regionName;
  final bool isActive;

  const AdminMunicipality({required this.id, required this.name, this.nameAlt, this.provinceCode, this.provinceName, required this.regionId, required this.regionName, required this.isActive});
  factory AdminMunicipality.fromJson(Map<String, dynamic> json) => AdminMunicipality(id: json['id'] as String, name: json['name'] as String, nameAlt: json['name_alt'] as String?, provinceCode: json['province_code'] as String?, provinceName: json['province_name'] as String?, regionId: json['region_id'] as String, regionName: (json['region'] as Map?)?['name'] as String? ?? json['region_name'] as String? ?? '', isActive: json['is_active'] as bool? ?? true);
}

class UnitUsage {
  final int profiles;
  final int posts;
  final int events;
  final int calendars;
  const UnitUsage({required this.profiles, required this.posts, required this.events, required this.calendars});
  int get total => profiles + posts + events + calendars;
}

class AdminUnitBoundary {
  final String unitId; final String unitName; final String unitType; final String? code; final String regionId; final Map<String, dynamic> geoJson; final double areaM2; final String? source; final DateTime updatedAt;
  const AdminUnitBoundary({required this.unitId, required this.unitName, required this.unitType, this.code, required this.regionId, required this.geoJson, required this.areaM2, this.source, required this.updatedAt});
  factory AdminUnitBoundary.fromJson(Map<String, dynamic> json) { final unit = Map<String, dynamic>.from(json['unit'] as Map? ?? const {}); return AdminUnitBoundary(unitId: json['unit_id'] as String, unitName: unit['name'] as String? ?? '', unitType: unit['unit_type'] as String? ?? '', code: unit['code'] as String?, regionId: unit['region_id'] as String? ?? '', geoJson: Map<String, dynamic>.from(json['geojson'] as Map), areaM2: (json['area_m2'] as num?)?.toDouble() ?? 0, source: json['source'] as String?, updatedAt: DateTime.parse(json['updated_at'] as String).toUtc()); }
}