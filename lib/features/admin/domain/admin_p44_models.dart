class AdminCalendarsStats {
  final List<AdminCountryCalendarStats> countries;
  final List<AdminRegionCalendarStats> regions;
  final List<AdminExpiringCalendar> expiring;
  final String version;

  const AdminCalendarsStats({required this.countries, required this.regions, required this.expiring, required this.version});
  factory AdminCalendarsStats.fromJson(Map<String, dynamic> json) => AdminCalendarsStats(
    countries: _objects(json['countries']).map(AdminCountryCalendarStats.fromJson).toList(),
    regions: _objects(json['regions']).map(AdminRegionCalendarStats.fromJson).toList(),
    expiring: _objects(json['expiring_30d']).map(AdminExpiringCalendar.fromJson).toList(),
    version: json['version']?.toString() ?? '',
  );
}

class AdminCountryCalendarStats {
  final String countryCode;
  final String seasonLabel;
  final int regionsTotal, regionsCovered, published, drafts, species, unitsWithArea, layersPublished;

  const AdminCountryCalendarStats({required this.countryCode, required this.seasonLabel, required this.regionsTotal, required this.regionsCovered, required this.published, required this.drafts, required this.species, required this.unitsWithArea, required this.layersPublished});
  factory AdminCountryCalendarStats.fromJson(Map<String, dynamic> json) => AdminCountryCalendarStats(countryCode: json['country_code']?.toString() ?? '', seasonLabel: json['season_label']?.toString() ?? '', regionsTotal: _integer(json['regions_total']), regionsCovered: _integer(json['regions_covered']), published: _integer(json['published']), drafts: _integer(json['drafts']), species: _integer(json['species']), unitsWithArea: _integer(json['units_with_area']), layersPublished: _integer(json['layers_published']));
}

class AdminRegionCalendarStats {
  final String regionId, countryCode, name;
  final int published, drafts, nextSeasonDrafts;
  final String? currentSeason;
  final DateTime? lastUpdate;

  const AdminRegionCalendarStats({required this.regionId, required this.countryCode, required this.name, required this.published, required this.drafts, this.currentSeason, required this.nextSeasonDrafts, this.lastUpdate});
  factory AdminRegionCalendarStats.fromJson(Map<String, dynamic> json) => AdminRegionCalendarStats(regionId: json['region_id']?.toString() ?? '', countryCode: json['country_code']?.toString() ?? '', name: json['name']?.toString() ?? '', published: _integer(json['published']), drafts: _integer(json['drafts']), currentSeason: json['current_season']?.toString(), nextSeasonDrafts: _integer(json['next_season_drafts']), lastUpdate: _date(json['last_update']));
}

class AdminExpiringCalendar {
  final String calendarId, regionName, speciesName, seasonLabel;
  final DateTime validTo;
  const AdminExpiringCalendar({required this.calendarId, required this.regionName, required this.speciesName, required this.seasonLabel, required this.validTo});
  factory AdminExpiringCalendar.fromJson(Map<String, dynamic> json) => AdminExpiringCalendar(calendarId: json['calendar_id']?.toString() ?? '', regionName: json['region_name']?.toString() ?? '', speciesName: json['species_name']?.toString() ?? '', seasonLabel: json['season_label']?.toString() ?? '', validTo: _date(json['valid_to']) ?? DateTime.fromMillisecondsSinceEpoch(0));
}

class AdminCalendarRowP44 {
  final String id, countryCode, regionId, regionName, speciesId, scientificName, speciesName, category, seasonLabel, status;
  final String? huntingUnitId, unitName, sourceName, sourceUrl, notes, publishedByName;
  final DateTime validFrom, validTo, updatedAt;
  final DateTime? publishedAt;
  final int rulesCount, total;
  final bool hasTimeRule, isCurrent;

  const AdminCalendarRowP44({required this.id, required this.countryCode, required this.regionId, required this.regionName, this.huntingUnitId, this.unitName, required this.speciesId, required this.scientificName, required this.speciesName, required this.category, required this.seasonLabel, required this.validFrom, required this.validTo, required this.status, this.sourceName, this.sourceUrl, this.notes, required this.rulesCount, required this.hasTimeRule, this.publishedByName, this.publishedAt, required this.updatedAt, required this.isCurrent, required this.total});
  factory AdminCalendarRowP44.fromJson(Map<String, dynamic> json) => AdminCalendarRowP44(id: json['id'].toString(), countryCode: json['country_code']?.toString() ?? '', regionId: json['region_id']?.toString() ?? '', regionName: json['region_name']?.toString() ?? '', huntingUnitId: json['hunting_unit_id']?.toString(), unitName: json['unit_name']?.toString(), speciesId: json['species_id']?.toString() ?? '', scientificName: json['scientific_name']?.toString() ?? '', speciesName: json['species_name']?.toString() ?? '', category: json['category']?.toString() ?? 'other', seasonLabel: json['season_label']?.toString() ?? '', validFrom: _date(json['valid_from'])!, validTo: _date(json['valid_to'])!, status: json['status']?.toString() ?? 'draft', sourceName: json['source_name']?.toString(), sourceUrl: json['source_url']?.toString(), notes: json['notes']?.toString(), rulesCount: _integer(json['rules_count']), hasTimeRule: json['has_time_rule'] == true, publishedByName: json['published_by_name']?.toString(), publishedAt: _date(json['published_at']), updatedAt: _date(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0), isCurrent: json['is_current'] == true, total: _integer(json['total']));
}

class CalendarValidation {
  final bool ok;
  final List<CalendarIssue> issues;
  const CalendarValidation({required this.ok, required this.issues});
  factory CalendarValidation.fromJson(Map<String, dynamic> json) => CalendarValidation(ok: json['ok'] == true, issues: _objects(json['issues']).map(CalendarIssue.fromJson).toList());
}

class CalendarIssue {
  final String code, severity;
  final Object? detail;
  const CalendarIssue({required this.code, required this.severity, this.detail});
  factory CalendarIssue.fromJson(Map<String, dynamic> json) => CalendarIssue(code: json['code']?.toString() ?? '', severity: json['severity']?.toString() ?? 'info', detail: json['detail']);
}

class AdminSpeciesP44 {
  final String id, scientificName, category;
  final bool isActive;
  final String? imagePath;
  final Map<String, String> names;
  final List<String> missingLocales;
  final int calendars, publishedCalendars, sightings, logEntries, alerts, total;
  final DateTime? updatedAt;

  const AdminSpeciesP44({required this.id, required this.scientificName, required this.category, required this.isActive, this.imagePath, required this.names, required this.missingLocales, required this.calendars, required this.publishedCalendars, required this.sightings, required this.logEntries, required this.alerts, required this.total, this.updatedAt});
  factory AdminSpeciesP44.fromJson(Map<String, dynamic> json) { final rawNames = json['names'] as Map? ?? const {}; return AdminSpeciesP44(id: json['id'].toString(), scientificName: json['scientific_name']?.toString() ?? '', category: json['category']?.toString() ?? 'other', isActive: json['is_active'] != false, imagePath: json['image_path']?.toString(), names: {for (final entry in rawNames.entries) entry.key.toString(): entry.value.toString()}, missingLocales: [for (final value in json['missing_locales'] as List? ?? const []) value.toString()], calendars: _integer(json['calendars']), publishedCalendars: _integer(json['published_calendars']), sightings: _integer(json['sightings']), logEntries: _integer(json['log_entries']), alerts: _integer(json['alerts']), total: _integer(json['total']), updatedAt: _date(json['updated_at'])); }
  int get uses => calendars + sightings + logEntries + alerts;
}

class AdminMapLayerP44 {
  final String id, countryCode, kind, name, color, status;
  final String? regionId, regionName, description, sourceName, sourceUrl, updatedByName;
  final DateTime? validFrom, validTo, updatedAt;
  final int featureCount, sizeKb;
  final double areaM2;
  final double? minLat, minLng, maxLat, maxLng;

  const AdminMapLayerP44({required this.id, required this.countryCode, this.regionId, this.regionName, required this.kind, required this.name, this.description, required this.color, this.sourceName, this.sourceUrl, required this.status, this.validFrom, this.validTo, required this.featureCount, required this.areaM2, required this.sizeKb, this.minLat, this.minLng, this.maxLat, this.maxLng, this.updatedByName, this.updatedAt});
  factory AdminMapLayerP44.fromJson(Map<String, dynamic> json) => AdminMapLayerP44(id: json['id'].toString(), countryCode: json['country_code']?.toString() ?? '', regionId: json['region_id']?.toString(), regionName: json['region_name']?.toString(), kind: json['kind']?.toString() ?? 'other', name: json['name']?.toString() ?? '', description: json['description']?.toString(), color: json['color']?.toString() ?? '', sourceName: json['source_name']?.toString(), sourceUrl: json['source_url']?.toString(), status: json['status']?.toString() ?? 'draft', validFrom: _date(json['valid_from']), validTo: _date(json['valid_to']), featureCount: _integer(json['feature_count']), areaM2: _decimal(json['area_m2']), sizeKb: _integer(json['size_kb']), minLat: _nullableDecimal(json['min_lat']), minLng: _nullableDecimal(json['min_lng']), maxLat: _nullableDecimal(json['max_lat']), maxLng: _nullableDecimal(json['max_lng']), updatedByName: json['updated_by_name']?.toString(), updatedAt: _date(json['updated_at']));
}

List<Map<String, dynamic>> _objects(Object? value) => [for (final item in value as List? ?? const []) if (item is Map) Map<String, dynamic>.from(item)];
int _integer(Object? value) => (value as num?)?.toInt() ?? int.tryParse(value?.toString() ?? '') ?? 0;
double _decimal(Object? value) => (value as num?)?.toDouble() ?? double.tryParse(value?.toString() ?? '') ?? 0;
double? _nullableDecimal(Object? value) => value == null ? null : _decimal(value);
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString());