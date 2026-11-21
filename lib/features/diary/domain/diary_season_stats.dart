class DiarySeasonTotals {
  final int outings;
  final double hours;
  final int harvests;
  final int outingsWithHarvest;
  final int distanceM;
  final int units;
  final int zones;
  final int bestOutingHarvest;

  const DiarySeasonTotals({required this.outings, required this.hours, required this.harvests, required this.outingsWithHarvest, required this.distanceM, required this.units, required this.zones, required this.bestOutingHarvest});

  factory DiarySeasonTotals.fromJson(Map<String, dynamic> json) => DiarySeasonTotals(
    outings: (json['outings'] as num?)?.toInt() ?? 0,
    hours: (json['hours'] as num?)?.toDouble() ?? 0,
    harvests: (json['harvests'] as num?)?.toInt() ?? 0,
    outingsWithHarvest: (json['outings_with_harvest'] as num?)?.toInt() ?? 0,
    distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
    units: (json['units'] as num?)?.toInt() ?? 0,
    zones: (json['zones'] as num?)?.toInt() ?? 0,
    bestOutingHarvest: (json['best_outing_harvest'] as num?)?.toInt() ?? 0,
  );
}

class DiarySpeciesStat {
  final String speciesId;
  final String scientificName;
  final String nameIt;
  final String category;
  final int harvests;
  final int seen;
  final int shots;
  final int outings;
  const DiarySpeciesStat({required this.speciesId, required this.scientificName, required this.nameIt, required this.category, required this.harvests, required this.seen, required this.shots, required this.outings});
  factory DiarySpeciesStat.fromJson(Map<String, dynamic> json) => DiarySpeciesStat(speciesId: json['species_id'] as String? ?? '', scientificName: json['scientific_name'] as String? ?? '', nameIt: json['name_it'] as String? ?? '', category: json['category'] as String? ?? 'other', harvests: (json['harvests'] as num?)?.toInt() ?? 0, seen: (json['seen'] as num?)?.toInt() ?? 0, shots: (json['shots'] as num?)?.toInt() ?? 0, outings: (json['outings'] as num?)?.toInt() ?? 0);
}

class DiaryPeriodStat {
  final String key;
  final int outings;
  final int harvests;
  final double hours;
  const DiaryPeriodStat({required this.key, required this.outings, required this.harvests, this.hours = 0});
  factory DiaryPeriodStat.fromJson(Map<String, dynamic> json, String keyName) => DiaryPeriodStat(key: json[keyName]?.toString() ?? '', outings: (json['outings'] as num?)?.toInt() ?? 0, harvests: (json['harvests'] as num?)?.toInt() ?? 0, hours: (json['hours'] as num?)?.toDouble() ?? 0);
}

class DiaryPlaceStat {
  final String label;
  final String? unitId;
  final int outings;
  final int harvests;
  const DiaryPlaceStat({required this.label, this.unitId, required this.outings, required this.harvests});
  factory DiaryPlaceStat.fromJson(Map<String, dynamic> json) => DiaryPlaceStat(label: json['label'] as String? ?? '', unitId: json['unit_id'] as String?, outings: (json['outings'] as num?)?.toInt() ?? 0, harvests: (json['harvests'] as num?)?.toInt() ?? 0);
}

class DiaryDogStat {
  final String dogId;
  final String name;
  final String? breed;
  final String? avatarUrl;
  final int outings;
  final int harvests;
  const DiaryDogStat({required this.dogId, required this.name, this.breed, this.avatarUrl, required this.outings, required this.harvests});
  factory DiaryDogStat.fromJson(Map<String, dynamic> json) => DiaryDogStat(dogId: json['dog_id'] as String? ?? '', name: json['name'] as String? ?? '', breed: json['breed'] as String?, avatarUrl: json['avatar_url'] as String?, outings: (json['outings'] as num?)?.toInt() ?? 0, harvests: (json['harvests'] as num?)?.toInt() ?? 0);
}

class DiaryWeatherStats {
  final double? averageTemperature;
  final int rainyOutings;
  final int withWeather;
  const DiaryWeatherStats({this.averageTemperature, required this.rainyOutings, required this.withWeather});
  factory DiaryWeatherStats.fromJson(Map<String, dynamic> json) => DiaryWeatherStats(averageTemperature: (json['avg_temperature'] as num?)?.toDouble(), rainyOutings: (json['rainy_outings'] as num?)?.toInt() ?? 0, withWeather: (json['with_weather'] as num?)?.toInt() ?? 0);
}

class DiarySeasonStats {
  final String seasonLabel;
  final DateTime? seasonFrom;
  final DateTime? seasonTo;
  final String userId;
  final DiarySeasonTotals totals;
  final List<DiarySpeciesStat> bySpecies;
  final List<DiaryPeriodStat> byCategory;
  final List<DiaryPeriodStat> byMonth;
  final List<DiaryPeriodStat> byMethod;
  final List<DiaryPlaceStat> byPlace;
  final List<DiaryDogStat> byDog;
  final List<DiaryPeriodStat> byWeekday;
  final DiaryWeatherStats weather;

  const DiarySeasonStats({required this.seasonLabel, this.seasonFrom, this.seasonTo, required this.userId, required this.totals, required this.bySpecies, required this.byCategory, required this.byMonth, required this.byMethod, required this.byPlace, required this.byDog, required this.byWeekday, required this.weather});

  factory DiarySeasonStats.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
    List<Map<String, dynamic>> rows(String key) => (json[key] as List? ?? const []).whereType<Map>().map((value) => Map<String, dynamic>.from(value)).toList();
    return DiarySeasonStats(
      seasonLabel: json['season_label'] as String? ?? '', seasonFrom: DateTime.tryParse(json['season_from']?.toString() ?? ''), seasonTo: DateTime.tryParse(json['season_to']?.toString() ?? ''), userId: json['user_id'] as String? ?? '', totals: DiarySeasonTotals.fromJson(map(json['totals'])),
      bySpecies: rows('by_species').map(DiarySpeciesStat.fromJson).toList(), byCategory: rows('by_category').map((value) => DiaryPeriodStat.fromJson(value, 'category')).toList(), byMonth: rows('by_month').map((value) => DiaryPeriodStat.fromJson(value, 'month')).toList(), byMethod: rows('by_method').map((value) => DiaryPeriodStat.fromJson(value, 'method')).toList(), byPlace: rows('by_place').map(DiaryPlaceStat.fromJson).toList(), byDog: rows('by_dog').map(DiaryDogStat.fromJson).toList(), byWeekday: rows('by_weekday').map((value) => DiaryPeriodStat.fromJson(value, 'isodow')).toList(), weather: DiaryWeatherStats.fromJson(map(json['weather'])),
    );
  }
}