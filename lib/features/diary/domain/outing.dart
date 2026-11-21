enum HuntingMethod {
  vagante,
  appostamentoFisso,
  appostamentoTemporaneo,
  braccata,
  girata,
  selezione,
  cerca,
  altro;

  String get code => switch (this) {
    HuntingMethod.appostamentoFisso => 'appostamento_fisso',
    HuntingMethod.appostamentoTemporaneo => 'appostamento_temporaneo',
    _ => name,
  };
  String get labelKey => 'diary.method.$code';
  static HuntingMethod fromCode(String? value) => values.firstWhere((item) => item.code == value, orElse: () => HuntingMethod.altro);
}

enum OutingVisibility { private, followers, public;
  String get code => name;
  String get labelKey => 'diary.visibility.$name';
}

class OutingSpecies {
  final String speciesId;
  final String scientificName;
  final String name;
  final String category;
  final int harvestCount;
  final int seenCount;
  final int shots;
  final String? notes;
  const OutingSpecies({required this.speciesId, required this.scientificName, required this.name, required this.category, required this.harvestCount, required this.seenCount, required this.shots, this.notes});

  factory OutingSpecies.fromJson(Map<String, dynamic> json, [String locale = 'it']) {
    final species = json['species'] is Map ? Map<String, dynamic>.from(json['species'] as Map) : json;
    final names = (species['names'] as List? ?? const []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    String? localized(String code) => names.where((item) => item['locale'] == code).firstOrNull?['name'] as String?;
    return OutingSpecies(
      speciesId: (json['species_id'] ?? species['id']) as String,
      scientificName: species['scientific_name'] as String? ?? json['scientific_name'] as String? ?? '',
      name: json['name'] as String? ?? json['name_it'] as String? ?? localized(locale) ?? localized('it') ?? species['scientific_name'] as String? ?? '',
      category: species['category'] as String? ?? json['category'] as String? ?? '',
      harvestCount: (json['harvest_count'] as num?)?.toInt() ?? 0,
      seenCount: (json['seen_count'] as num?)?.toInt() ?? 0,
      shots: (json['shots'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toRpc() => {'species_id': speciesId, 'harvest_count': harvestCount, 'seen_count': seenCount, 'shots': shots, 'notes': notes};
}

class OutingDog {
  final String id;
  final String name;
  final String? breed;
  final String? avatarUrl;
  const OutingDog({required this.id, required this.name, this.breed, this.avatarUrl});
  factory OutingDog.fromJson(Map<String, dynamic> json) {
    final dog = json['dog'] is Map ? Map<String, dynamic>.from(json['dog'] as Map) : json;
    return OutingDog(id: dog['id'] as String, name: dog['name'] as String? ?? '', breed: dog['breed'] as String?, avatarUrl: dog['avatar_url'] as String?);
  }
}

class OutingWeather {
  final double? temperature;
  final double? apparentTemperature;
  final int? weatherCode;
  final double? windSpeed;
  final double? windDirection;
  final double? precipitation;
  final int? humidity;
  final String? moonPhaseName;
  final double? moonIllumination;
  final String? source;
  final DateTime? fetchedAt;
  final String? hour;
  const OutingWeather({this.temperature, this.apparentTemperature, this.weatherCode, this.windSpeed, this.windDirection, this.precipitation, this.humidity, this.moonPhaseName, this.moonIllumination, this.source, this.fetchedAt, this.hour});
  bool get isDay { final value = int.tryParse(hour?.split(':').first ?? ''); return value == null || value >= 6 && value < 19; }
  factory OutingWeather.fromJson(Map<String, dynamic> json) => OutingWeather(temperature: (json['temperature'] as num?)?.toDouble(), apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble(), weatherCode: (json['weather_code'] as num?)?.toInt(), windSpeed: (json['wind_speed'] as num?)?.toDouble(), windDirection: (json['wind_direction'] as num?)?.toDouble(), precipitation: (json['precipitation'] as num?)?.toDouble(), humidity: (json['humidity'] as num?)?.toInt(), moonPhaseName: json['moon_phase_name'] as String?, moonIllumination: (json['moon_illumination'] as num?)?.toDouble(), source: json['source'] as String?, fetchedAt: DateTime.tryParse(json['fetched_at'] as String? ?? ''), hour: json['hour'] as String?);
  Map<String, dynamic> toJson() => {'temperature': temperature, 'apparent_temperature': apparentTemperature, 'weather_code': weatherCode, 'wind_speed': windSpeed, 'wind_direction': windDirection, 'precipitation': precipitation, 'humidity': humidity, 'moon_phase_name': moonPhaseName, 'moon_illumination': moonIllumination, 'source': source, 'fetched_at': fetchedAt?.toUtc().toIso8601String(), 'hour': hour};
}

class OutingPoint {
  final double lat;
  final double lng;
  final double? accuracyM;
  const OutingPoint({required this.lat, required this.lng, this.accuracyM});
  factory OutingPoint.fromJson(Map<String, dynamic> json) => OutingPoint(lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble(), accuracyM: (json['accuracy_m'] as num?)?.toDouble());
}

class Outing {
  final String id;
  final String userId;
  final String? title;
  final String? zoneName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMin;
  final HuntingMethod method;
  final OutingVisibility visibility;
  final String? regionId;
  final String? regionName;
  final String? unitId;
  final String? unitName;
  final String? unitType;
  final String? municipalityId;
  final String? municipalityName;
  final String? provinceCode;
  final int harvestTotal;
  final int mediaCount;
  final int? distanceM;
  final String? notes;
  final OutingWeather? weather;
  final List<OutingSpecies> species;
  final List<OutingDog> dogs;
  final List<OutingMedia> media;
  final OutingPoint? point;
  final String? coverPath;
  final String? coverThumbnailPath;
  final String? seasonLabel;
  const Outing({required this.id, required this.userId, this.title, this.zoneName, required this.startedAt, this.endedAt, this.durationMin, required this.method, required this.visibility, this.regionId, this.regionName, this.unitId, this.unitName, this.unitType, this.municipalityId, this.municipalityName, this.provinceCode, required this.harvestTotal, required this.mediaCount, this.distanceM, this.notes, this.weather, required this.species, required this.dogs, this.media = const [], this.point, this.coverPath, this.coverThumbnailPath, this.seasonLabel});

  factory Outing.fromJson(Map<String, dynamic> json, [String locale = 'it']) {
    Map<String, dynamic>? embedded(String key) => json[key] is Map ? Map<String, dynamic>.from(json[key] as Map) : null;
    final region = embedded('region'); final unit = embedded('unit'); final municipality = embedded('municipality');
    final pointValue = json['point']; final pointJson = pointValue is List ? pointValue.firstOrNull : pointValue;
    final weatherJson = json['weather'];
    return Outing(
      id: json['id'] as String, userId: json['user_id'] as String, title: json['title'] as String?, zoneName: json['zone_name'] as String?, startedAt: DateTime.parse(json['started_at'] as String), endedAt: DateTime.tryParse(json['ended_at'] as String? ?? ''), durationMin: (json['duration_min'] as num?)?.toInt(), method: HuntingMethod.fromCode(json['hunting_method'] as String?), visibility: OutingVisibility.values.firstWhere((item) => item.code == json['visibility'], orElse: () => OutingVisibility.private),
      regionId: json['region_id'] as String?, regionName: json['region_name'] as String? ?? region?['name'] as String?, unitId: json['hunting_unit_id'] as String?, unitName: json['unit_name'] as String? ?? unit?['name'] as String?, unitType: unit?['unit_type'] as String?, municipalityId: json['municipality_id'] as String?, municipalityName: json['municipality_name'] as String? ?? municipality?['name'] as String?, provinceCode: municipality?['province_code'] as String?,
      harvestTotal: (json['harvest_total'] as num?)?.toInt() ?? 0, mediaCount: (json['media_count'] as num?)?.toInt() ?? 0, distanceM: (json['distance_m'] as num?)?.toInt(), notes: json['notes'] as String?, weather: weatherJson is Map && weatherJson.isNotEmpty ? OutingWeather.fromJson(Map<String, dynamic>.from(weatherJson)) : null,
      species: [for (final item in json['species'] as List? ?? const []) OutingSpecies.fromJson(Map<String, dynamic>.from(item as Map), locale)], dogs: [for (final item in json['dogs'] as List? ?? const []) OutingDog.fromJson(Map<String, dynamic>.from(item as Map))], media: [for (final item in json['media'] as List? ?? const []) OutingMedia.fromJson(Map<String, dynamic>.from(item as Map))], point: pointJson is Map ? OutingPoint.fromJson(Map<String, dynamic>.from(pointJson)) : null,
      coverPath: json['cover_path'] as String?, coverThumbnailPath: json['cover_thumbnail_path'] as String?, seasonLabel: json['season_label'] as String?,
    );
  }
}

class OutingMedia {
  final String id;
  final String path;
  final String kind;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailPath;
  final String? caption;
  final int sortOrder;
  const OutingMedia({required this.id, required this.path, required this.kind, this.width, this.height, this.durationMs, this.thumbnailPath, this.caption, required this.sortOrder});
  factory OutingMedia.fromJson(Map<String, dynamic> json) => OutingMedia(id: json['id'] as String, path: json['path'] as String, kind: json['kind'] as String, width: (json['width'] as num?)?.toInt(), height: (json['height'] as num?)?.toInt(), durationMs: (json['duration_ms'] as num?)?.toInt(), thumbnailPath: json['thumbnail_path'] as String?, caption: json['caption'] as String?, sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0);
}