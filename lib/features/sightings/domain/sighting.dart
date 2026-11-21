import 'package:flutter/material.dart';

enum SightingKind {
  sighting,
  tracks,
  damage,
  carcass;

  String get code => name;
  String get labelKey => 'sightings.kind.$code';
  IconData get icon => switch (this) { SightingKind.sighting => Icons.visibility_outlined, SightingKind.tracks => Icons.pets_outlined, SightingKind.damage => Icons.grass_outlined, SightingKind.carcass => Icons.warning_amber_rounded };
  static SightingKind fromCode(String? code) => values.firstWhere((value) => value.code == code, orElse: () => sighting);
}

enum SightingVisibility {
  private,
  friends,
  public;

  String get code => name;
  String get labelKey => 'sightings.visibility.$code';
  static SightingVisibility fromCode(String? code) => values.firstWhere((value) => value.code == code, orElse: () => public);
}

class SightingSpecies {
  final String id;
  final String scientificName;
  final String category;
  final String name;
  final Map<String, String> names;
  const SightingSpecies({required this.id, required this.scientificName, required this.category, required this.name, this.names = const {}});

  factory SightingSpecies.fromJson(Map<String, dynamic> json) {
    final names = <String, String>{};
    final raw = json['names'];
    if (raw is Map) raw.forEach((key, value) { if (value != null) names['$key'] = '$value'; });
    if (raw is List) for (final row in raw.whereType<Map>()) { if (row['locale'] != null && row['name'] != null) names['${row['locale']}'] = '${row['name']}'; }
    return SightingSpecies(id: '${json['id'] ?? json['species_id'] ?? ''}', scientificName: '${json['scientific_name'] ?? ''}', category: '${json['category'] ?? ''}', name: '${json['name'] ?? json['species_name'] ?? names['it'] ?? json['scientific_name'] ?? ''}', names: names);
  }
}

class SightingPerson {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? verificationLevel;
  const SightingPerson({required this.id, required this.username, required this.displayName, this.avatarUrl, this.verificationLevel});
  factory SightingPerson.fromJson(Map<String, dynamic> json) => SightingPerson(id: '${json['id'] ?? ''}', username: '${json['username'] ?? ''}', displayName: '${json['display_name'] ?? json['username'] ?? ''}', avatarUrl: json['avatar_url'] as String?, verificationLevel: json['verification_level'] as String?);
}

class SightingPlace {
  final String id;
  final String name;
  final String? code;
  final String? provinceCode;
  final String? unitType;
  const SightingPlace({required this.id, required this.name, this.code, this.provinceCode, this.unitType});
  factory SightingPlace.fromJson(Map<String, dynamic> json) => SightingPlace(id: '${json['id'] ?? ''}', name: '${json['name'] ?? ''}', code: json['code'] as String?, provinceCode: json['province_code'] as String?, unitType: json['unit_type'] as String?);
}

class SightingOuting {
  final String id;
  final String? title;
  final String? zoneName;
  final DateTime startedAt;
  const SightingOuting({required this.id, this.title, this.zoneName, required this.startedAt});
  factory SightingOuting.fromJson(Map<String, dynamic> json) => SightingOuting(id: '${json['id']}', title: json['title'] as String?, zoneName: json['zone_name'] as String?, startedAt: DateTime.parse('${json['started_at']}'));
}

class Sighting {
  final String id;
  final SightingKind kind;
  final DateTime sightedAt;
  final int animalsCount;
  final String? notes;
  final SightingVisibility visibility;
  final double? lat;
  final double? lng;
  final bool isExact;
  final bool isMine;
  final double? accuracyM;
  final String? mediaPath;
  final String? thumbnailPath;
  final String? logId;
  final String? seasonLabel;
  final SightingSpecies species;
  final SightingPlace? municipality;
  final SightingPlace? region;
  final SightingPlace? unit;
  const Sighting({required this.id, required this.kind, required this.sightedAt, required this.animalsCount, this.notes, required this.visibility, this.lat, this.lng, required this.isExact, required this.isMine, this.accuracyM, this.mediaPath, this.thumbnailPath, this.logId, this.seasonLabel, required this.species, this.municipality, this.region, this.unit});

  factory Sighting.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(String key) => json[key] is Map ? Map<String, dynamic>.from(json[key] as Map) : null;
    final speciesJson = map('species') ?? {'id': json['species_id'], 'name': json['species_name'], 'scientific_name': json['scientific_name'], 'category': json['category']};
    SightingPlace? place(String key, String nameKey) { final value = map(key); if (value != null) return SightingPlace.fromJson(value); final name = json[nameKey] as String?; return name == null ? null : SightingPlace(id: '${json['${key}_id'] ?? ''}', name: name); }
    return Sighting(id: '${json['id']}', kind: SightingKind.fromCode(json['kind'] as String?), sightedAt: DateTime.parse('${json['sighted_at']}'), animalsCount: (json['animals_count'] as num?)?.toInt() ?? 1, notes: json['notes'] as String?, visibility: SightingVisibility.fromCode(json['visibility'] as String?), lat: (json['lat'] as num?)?.toDouble(), lng: (json['lng'] as num?)?.toDouble(), isExact: json['is_exact'] == true, isMine: json['is_mine'] == true, accuracyM: (json['accuracy_m'] as num?)?.toDouble(), mediaPath: json['media_path'] as String?, thumbnailPath: json['thumbnail_path'] as String?, logId: json['log_id'] as String?, seasonLabel: json['season_label'] as String?, species: SightingSpecies.fromJson(speciesJson), municipality: place('municipality', 'municipality_name'), region: place('region', 'region_name'), unit: place('unit', 'unit_name'));
  }
}

class NearbySighting extends Sighting {
  final SightingPerson author;
  final double distanceM;
  const NearbySighting({required super.id, required super.kind, required super.sightedAt, required super.animalsCount, required super.visibility, super.lat, super.lng, required super.isExact, required super.isMine, super.mediaPath, super.thumbnailPath, required super.species, super.municipality, required this.author, required this.distanceM});
  factory NearbySighting.fromJson(Map<String, dynamic> json) {
    final base = Sighting.fromJson(json);
    return NearbySighting(id: base.id, kind: base.kind, sightedAt: base.sightedAt, animalsCount: base.animalsCount, visibility: base.visibility, lat: base.lat, lng: base.lng, isExact: base.isExact, isMine: base.isMine, mediaPath: base.mediaPath, thumbnailPath: base.thumbnailPath, species: base.species, municipality: base.municipality, distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0, author: SightingPerson(id: '${json['author_id'] ?? ''}', username: '${json['author_username'] ?? ''}', displayName: '${json['author_display_name'] ?? json['author_username'] ?? ''}', avatarUrl: json['author_avatar_url'] as String?));
  }
}

class SightingHeatCell {
  final double lat, lng;
  final int sightings, animals, speciesCount;
  final DateTime lastAt;
  final String? topSpeciesId, topSpeciesName;
  const SightingHeatCell({required this.lat, required this.lng, required this.sightings, required this.animals, required this.speciesCount, required this.lastAt, this.topSpeciesId, this.topSpeciesName});
  factory SightingHeatCell.fromJson(Map<String, dynamic> json) => SightingHeatCell(lat: (json['cell_lat'] as num).toDouble(), lng: (json['cell_lng'] as num).toDouble(), sightings: (json['sightings'] as num?)?.toInt() ?? 0, animals: (json['animals'] as num?)?.toInt() ?? 0, speciesCount: (json['species_count'] as num?)?.toInt() ?? 0, lastAt: DateTime.parse('${json['last_at']}'), topSpeciesId: json['top_species_id'] as String?, topSpeciesName: json['top_species_name'] as String?);
}

class SpeciesActivity {
  final String speciesId, scientificName, category, speciesName;
  final int sightings, animals, prevSightings;
  final double? trendPct;
  final DateTime lastAt;
  const SpeciesActivity({required this.speciesId, required this.scientificName, required this.category, required this.speciesName, required this.sightings, required this.animals, required this.prevSightings, this.trendPct, required this.lastAt});
  factory SpeciesActivity.fromJson(Map<String, dynamic> json) => SpeciesActivity(speciesId: '${json['species_id']}', scientificName: '${json['scientific_name'] ?? ''}', category: '${json['category'] ?? ''}', speciesName: '${json['species_name'] ?? json['scientific_name'] ?? ''}', sightings: (json['sightings'] as num?)?.toInt() ?? 0, animals: (json['animals'] as num?)?.toInt() ?? 0, prevSightings: (json['prev_sightings'] as num?)?.toInt() ?? 0, trendPct: (json['trend_pct'] as num?)?.toDouble(), lastAt: DateTime.parse('${json['last_at']}'));
}

class SightingDetail extends Sighting {
  final bool hasPosition;
  final SightingPerson author;
  final SightingOuting? outing;
  const SightingDetail({required super.id, required super.kind, required super.sightedAt, required super.animalsCount, super.notes, required super.visibility, super.lat, super.lng, required super.isExact, required super.isMine, super.accuracyM, super.mediaPath, super.thumbnailPath, super.logId, required super.species, super.municipality, super.region, super.unit, required this.hasPosition, required this.author, this.outing});
  factory SightingDetail.fromJson(Map<String, dynamic> json) {
    final base = Sighting.fromJson(json);
    final author = Map<String, dynamic>.from(json['author'] as Map? ?? const {});
    final outing = json['outing'] is Map ? SightingOuting.fromJson(Map<String, dynamic>.from(json['outing'] as Map)) : null;
    return SightingDetail(id: base.id, kind: base.kind, sightedAt: base.sightedAt, animalsCount: base.animalsCount, notes: base.notes, visibility: base.visibility, lat: base.lat, lng: base.lng, isExact: base.isExact, isMine: base.isMine, accuracyM: base.accuracyM, mediaPath: base.mediaPath, thumbnailPath: base.thumbnailPath, logId: base.logId, species: base.species, municipality: base.municipality, region: base.region, unit: base.unit, hasPosition: json['has_position'] == true, author: SightingPerson.fromJson(author), outing: outing);
  }
}