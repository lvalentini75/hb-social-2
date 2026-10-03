class HuntingOuting {
  final String id;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? zoneName;
  final String? weather;
  final List<String> species;
  final List<String> dogIds;
  final int? harvestCount;
  final int? distanceMeters;
  final String? notes;
  final List<String> photoUrls;

  const HuntingOuting({required this.id, this.startedAt, this.endedAt, this.zoneName, this.weather, this.species = const [], this.dogIds = const [], this.harvestCount, this.distanceMeters, this.notes, this.photoUrls = const []});

  factory HuntingOuting.fromJson(Map<String, dynamic> json) => HuntingOuting(
    id: json['id'] as String,
    startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
    endedAt: DateTime.tryParse(json['ended_at'] as String? ?? ''),
    zoneName: json['zone_name'] as String?,
    weather: json['weather'] as String?,
    species: List<String>.from(json['species'] as List? ?? const []),
    dogIds: List<String>.from(json['dog_ids'] as List? ?? const []),
    harvestCount: (json['harvest_count'] as num?)?.toInt(),
    distanceMeters: (json['distance_meters'] as num?)?.toInt(),
    notes: json['notes'] as String?,
    photoUrls: List<String>.from(json['photo_urls'] as List? ?? const []),
  );

  Map<String, dynamic> toJson() => {'id': id, 'started_at': startedAt?.toUtc().toIso8601String(), 'ended_at': endedAt?.toUtc().toIso8601String(), 'zone_name': zoneName, 'weather': weather, 'species': species, 'dog_ids': dogIds, 'harvest_count': harvestCount, 'distance_meters': distanceMeters, 'notes': notes, 'photo_urls': photoUrls};
}