import 'package:hb_social/features/sightings/domain/sighting.dart';

enum SightingAlertArea { point, municipality, region }

class SightingAlert {
  final String id;
  final String name;
  final String? speciesId;
  final String? speciesName;
  final List<SightingKind> kinds;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? municipalityId;
  final String? municipalityName;
  final String? regionId;
  final String? regionName;
  final int minAnimals;
  final int cooldownMin;
  final bool isActive;
  final DateTime? lastFiredAt;
  final int fireCount;
  final DateTime createdAt;

  const SightingAlert({required this.id, required this.name, this.speciesId, this.speciesName, required this.kinds, this.lat, this.lng, required this.radiusKm, this.municipalityId, this.municipalityName, this.regionId, this.regionName, required this.minAnimals, required this.cooldownMin, required this.isActive, this.lastFiredAt, required this.fireCount, required this.createdAt});

  SightingAlertArea get area => municipalityId != null ? SightingAlertArea.municipality : regionId != null ? SightingAlertArea.region : SightingAlertArea.point;
  String get placeLabel => municipalityName ?? regionName ?? '${radiusKm.toStringAsFixed(radiusKm % 1 == 0 ? 0 : 1)} km';

  factory SightingAlert.fromJson(Map<String, dynamic> json) => SightingAlert(
    id: '${json['id']}', name: '${json['name'] ?? ''}', speciesId: json['species_id'] as String?, speciesName: json['species_name'] as String?,
    kinds: [for (final value in (json['kinds'] as List? ?? const [])) SightingKind.fromCode('$value')],
    lat: (json['lat'] as num?)?.toDouble(), lng: (json['lng'] as num?)?.toDouble(), radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 10,
    municipalityId: json['municipality_id'] as String?, municipalityName: json['municipality_name'] as String?, regionId: json['region_id'] as String?, regionName: json['region_name'] as String?,
    minAnimals: (json['min_animals'] as num?)?.toInt() ?? 1, cooldownMin: (json['cooldown_min'] as num?)?.toInt() ?? 60, isActive: json['is_active'] == true,
    lastFiredAt: json['last_fired_at'] == null ? null : DateTime.tryParse('${json['last_fired_at']}')?.toUtc(), fireCount: (json['fire_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse('${json['created_at']}').toUtc(),
  );
}

class SightingAlertInput {
  final String? id;
  final String name;
  final String? speciesId;
  final List<SightingKind> kinds;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? municipalityId;
  final String? regionId;
  final int minAnimals;
  final int cooldownMin;
  final bool isActive;
  const SightingAlertInput({this.id, required this.name, this.speciesId, required this.kinds, this.lat, this.lng, this.radiusKm = 10, this.municipalityId, this.regionId, this.minAnimals = 1, this.cooldownMin = 60, this.isActive = true});
}

class SightingAlertPrefill {
  final String? speciesId;
  final String? speciesName;
  final double? lat;
  final double? lng;
  const SightingAlertPrefill({this.speciesId, this.speciesName, this.lat, this.lng});
}