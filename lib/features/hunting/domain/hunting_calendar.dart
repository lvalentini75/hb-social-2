class CalendarDayInfo {
  final String calendarId;
  final String speciesId;
  final String scientificName;
  final String category;
  final String? nameIt;
  final String seasonLabel;
  final DateTime validFrom;
  final DateTime validTo;
  final String? sourceName;
  final String? sourceUrl;
  final String? notes;
  final bool isOpen;
  final String? timeRule;
  final int? bagDay;
  final int? bagSeason;
  final DateTime? nextOpen;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final bool? isOpenNow;

  const CalendarDayInfo({required this.calendarId, required this.speciesId, required this.scientificName, required this.category, this.nameIt, required this.seasonLabel, required this.validFrom, required this.validTo, this.sourceName, this.sourceUrl, this.notes, required this.isOpen, this.timeRule, this.bagDay, this.bagSeason, this.nextOpen, this.opensAt, this.closesAt, this.isOpenNow});

  factory CalendarDayInfo.fromJson(Map<String, dynamic> json) => CalendarDayInfo(
    calendarId: json['calendar_id'] as String,
    speciesId: json['species_id'] as String,
    scientificName: json['scientific_name'] as String,
    category: json['category'] as String? ?? 'other',
    nameIt: json['name_it'] as String?,
    seasonLabel: json['season_label'] as String? ?? '',
    validFrom: DateTime.parse(json['valid_from'] as String),
    validTo: DateTime.parse(json['valid_to'] as String),
    sourceName: json['source_name'] as String?,
    sourceUrl: json['source_url'] as String?,
    notes: json['notes'] as String?,
    isOpen: json['is_open'] as bool? ?? false,
    timeRule: json['time_rule'] as String?,
    bagDay: (json['bag_day'] as num?)?.toInt(),
    bagSeason: (json['bag_season'] as num?)?.toInt(),
    nextOpen: json['next_open'] == null ? null : DateTime.parse(json['next_open'] as String),
    opensAt: _dateTime(json['opens_at']),
    closesAt: _dateTime(json['closes_at']),
    isOpenNow: json['is_open_now'] as bool?,
  );

  String localizedName(Map<String, String> names) => names[speciesId] ?? nameIt ?? scientificName;
}

class HuntingDayInfo {
  final String? calendarId;
  final String speciesId;
  final String scientificName;
  final String category;
  final String? nameIt;
  final String? imagePath;
  final String regionId;
  final String? huntingUnitId;
  final String seasonLabel;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? sourceName;
  final String? sourceUrl;
  final String? notes;
  final DateTime day;
  final String? appliesTo;
  final bool inSeason;
  final bool isOpen;
  final String? closedReason;
  final List<int> allowedDays;
  final String? timeRule;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final bool? isOpenNow;
  final int? bagDay;
  final int? bagSeason;
  final DateTime? nextOpen;
  final DateTime? lastOpenDay;
  final List<CalendarRule> rules;

  const HuntingDayInfo({this.calendarId, required this.speciesId, required this.scientificName, required this.category, this.nameIt, this.imagePath, required this.regionId, this.huntingUnitId, required this.seasonLabel, this.validFrom, this.validTo, this.sourceName, this.sourceUrl, this.notes, required this.day, this.appliesTo, required this.inSeason, required this.isOpen, this.closedReason, this.allowedDays = const [], this.timeRule, this.opensAt, this.closesAt, this.isOpenNow, this.bagDay, this.bagSeason, this.nextOpen, this.lastOpenDay, this.rules = const []});

  factory HuntingDayInfo.fromJson(Map<String, dynamic> json) => HuntingDayInfo(
    calendarId: json['calendar_id'] as String?, speciesId: json['species_id'] as String? ?? '', scientificName: json['scientific_name'] as String? ?? '', category: json['category'] as String? ?? 'other', nameIt: json['name_it'] as String?, imagePath: json['image_path'] as String?, regionId: json['region_id'] as String? ?? '', huntingUnitId: json['hunting_unit_id'] as String?, seasonLabel: json['season_label'] as String? ?? '', validFrom: _dateTime(json['valid_from']), validTo: _dateTime(json['valid_to']), sourceName: json['source_name'] as String?, sourceUrl: json['source_url'] as String?, notes: json['notes'] as String?, day: _dateTime(json['date']) ?? DateTime.now(), appliesTo: json['applies_to'] as String?, inSeason: json['in_season'] as bool? ?? false, isOpen: json['is_open'] as bool? ?? false, closedReason: json['closed_reason'] as String?, allowedDays: [for (final value in json['allowed_days'] as List? ?? const []) (value as num).toInt()], timeRule: json['time_rule'] as String?, opensAt: _dateTime(json['opens_at']), closesAt: _dateTime(json['closes_at']), isOpenNow: json['is_open_now'] as bool?, bagDay: (json['bag_day'] as num?)?.toInt(), bagSeason: (json['bag_season'] as num?)?.toInt(), nextOpen: _dateTime(json['next_open']), lastOpenDay: _dateTime(json['last_open_day']), rules: [for (final value in json['rules'] as List? ?? const []) CalendarRule.fromJson(Map<String, dynamic>.from(value as Map))],
  );
}

class RegionCalendars {
  final String regionId;
  final String countryCode;
  final String code;
  final String name;
  final String kind;
  final int calendars;
  final String? seasonLabel;

  const RegionCalendars({required this.regionId, required this.countryCode, required this.code, required this.name, required this.kind, required this.calendars, this.seasonLabel});
  factory RegionCalendars.fromJson(Map<String, dynamic> json) => RegionCalendars(regionId: json['region_id'] as String, countryCode: json['country_code'] as String? ?? '', code: json['code'] as String? ?? '', name: json['name'] as String? ?? '', kind: json['kind'] as String? ?? 'region', calendars: (json['calendars'] as num?)?.toInt() ?? 0, seasonLabel: json['season_label'] as String?);
}

class CalendarChange {
  final DateTime changeDate;
  final String kind;
  final String speciesId;
  final String scientificName;
  final String? nameIt;
  final String category;
  final String calendarId;
  final String? notes;

  const CalendarChange({required this.changeDate, required this.kind, required this.speciesId, required this.scientificName, this.nameIt, required this.category, required this.calendarId, this.notes});
  factory CalendarChange.fromJson(Map<String, dynamic> json) => CalendarChange(changeDate: DateTime.parse(json['change_date'] as String), kind: json['kind'] as String, speciesId: json['species_id'] as String, scientificName: json['scientific_name'] as String, nameIt: json['name_it'] as String?, category: json['category'] as String? ?? 'other', calendarId: json['calendar_id'] as String, notes: json['notes'] as String?);
  String localizedName(Map<String, String> names) => names[speciesId] ?? nameIt ?? scientificName;
}

class SunTimes {
  final DateTime day;
  final DateTime sunrise;
  final DateTime sunset;
  const SunTimes({required this.day, required this.sunrise, required this.sunset});
}

class HuntingOverview {
  final String regionId;
  final String regionName;
  final DateTime day;
  final String? appliesTo;
  final List<CalendarDayInfo> entries;

  const HuntingOverview({required this.regionId, required this.regionName, required this.day, this.appliesTo, required this.entries});

  List<CalendarDayInfo> get open => entries.where((entry) => entry.isOpen).toList();
  List<CalendarDayInfo> get closed => entries.where((entry) => !entry.isOpen).toList();
  DateTime? get firstNextOpen {
    final dates = entries.map((entry) => entry.nextOpen).whereType<DateTime>().toList()..sort();
    return dates.firstOrNull;
  }
}

/// Raw calendar records remain available to the read-only admin console.
/// User-facing day status must only come from `calendar_overview`.
class HuntingCalendar {
  final String id;
  final String countryCode;
  final String regionId;
  final String? huntingUnitId;
  final String speciesId;
  final String seasonLabel;
  final DateTime validFrom;
  final DateTime validTo;
  final String? sourceName;
  final String? sourceUrl;
  final String? notes;
  final String status;
  final String? publishedBy;
  final DateTime? publishedAt;
  final SpeciesInfo species;
  final List<CalendarRule> rules;

  const HuntingCalendar({required this.id, required this.countryCode, required this.regionId, this.huntingUnitId, required this.speciesId, required this.seasonLabel, required this.validFrom, required this.validTo, this.sourceName, this.sourceUrl, this.notes, required this.status, this.publishedBy, this.publishedAt, required this.species, required this.rules});

  factory HuntingCalendar.fromJson(Map<String, dynamic> json) => HuntingCalendar(id: json['id'] as String, countryCode: (json['country_code'] as String).trim(), regionId: json['region_id'] as String, huntingUnitId: json['hunting_unit_id'] as String?, speciesId: json['species_id'] as String, seasonLabel: json['season_label'] as String, validFrom: DateTime.parse(json['valid_from'] as String), validTo: DateTime.parse(json['valid_to'] as String), sourceName: json['source_name'] as String?, sourceUrl: json['source_url'] as String?, notes: json['notes'] as String?, status: json['status'] as String, publishedBy: json['published_by'] as String?, publishedAt: json['published_at'] == null ? null : DateTime.parse(json['published_at'] as String).toUtc(), species: SpeciesInfo.fromJson(Map<String, dynamic>.from(json['species'] as Map)), rules: [for (final rule in json['rules'] as List? ?? const []) CalendarRule.fromJson(Map<String, dynamic>.from(rule as Map))]..sort((left, right) => left.sortOrder.compareTo(right.sortOrder)));
}

class CalendarRule {
  final String id;
  final String kind;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<int> allowedDays;
  final String? timeRule;
  final int? bagLimit;
  final String? bagPeriod;
  final String? notes;
  final String? appliesTo;
  final int sortOrder;

  const CalendarRule({required this.id, required this.kind, this.dateFrom, this.dateTo, this.allowedDays = const [], this.timeRule, this.bagLimit, this.bagPeriod, this.notes, this.appliesTo, required this.sortOrder});
  factory CalendarRule.fromJson(Map<String, dynamic> json) => CalendarRule(id: json['id'] as String? ?? '', kind: json['kind'] as String, dateFrom: json['date_from'] == null ? null : DateTime.parse(json['date_from'] as String), dateTo: json['date_to'] == null ? null : DateTime.parse(json['date_to'] as String), allowedDays: [for (final day in json['allowed_days'] as List? ?? const []) (day as num).toInt()], timeRule: json['time_rule'] as String?, bagLimit: (json['bag_limit'] as num?)?.toInt(), bagPeriod: json['bag_period'] as String?, notes: json['notes'] as String?, appliesTo: json['applies_to'] as String?, sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0);
}

DateTime? _dateTime(Object? value) => value is String ? DateTime.tryParse(value) : value as DateTime?;

class SpeciesInfo {
  final String id;
  final String scientificName;
  final String category;
  final Map<String, String> names;
  const SpeciesInfo({required this.id, required this.scientificName, required this.category, required this.names});
  factory SpeciesInfo.fromJson(Map<String, dynamic> json) {
    final names = <String, String>{};
    for (final value in json['names'] as List? ?? const []) { final row = Map<String, dynamic>.from(value as Map); if (row['locale'] != null && row['name'] != null) names[row['locale'] as String] = row['name'] as String; }
    return SpeciesInfo(id: json['id'] as String, scientificName: json['scientific_name'] as String, category: json['category'] as String, names: names);
  }
  String nameFor(String locale) => names[locale] ?? names['it'] ?? scientificName;
}