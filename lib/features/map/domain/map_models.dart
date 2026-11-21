import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum MapPointKind { altana, appostamento, parcheggio, rimessa, varco, fonte, ritrovo, altro;
  String get code => name;
  String get labelKey => 'map.kind.$code';
  IconData get icon => switch (this) {
    MapPointKind.altana => Icons.cell_tower_outlined,
    MapPointKind.appostamento => Icons.gps_fixed_rounded,
    MapPointKind.parcheggio => Icons.local_parking_rounded,
    MapPointKind.rimessa => Icons.grass_rounded,
    MapPointKind.varco => Icons.compare_arrows_rounded,
    MapPointKind.fonte => Icons.water_drop_outlined,
    MapPointKind.ritrovo => Icons.groups_2_outlined,
    MapPointKind.altro => Icons.location_on_outlined,
  };
  static MapPointKind parse(String? value) => values.firstWhere((item) => item.code == value, orElse: () => MapPointKind.altro);
}

enum MapPointVisibility { private, friends, public;
  String get code => name;
  String get labelKey => 'map.visibility.$name';
  String get descriptionKey => 'map.visibility_help.$name';
  static MapPointVisibility parse(String? value) => values.firstWhere((item) => item.code == value, orElse: () => MapPointVisibility.private);
}

class MapOwner {
  final String id; final String username; final String displayName; final String? avatarUrl;
  const MapOwner({required this.id, required this.username, required this.displayName, this.avatarUrl});
  factory MapOwner.fromJson(Map<String, dynamic> json) => MapOwner(id: json['id'] as String? ?? '', username: json['username'] as String? ?? '', displayName: json['display_name'] as String? ?? json['username'] as String? ?? '', avatarUrl: json['avatar_url'] as String?);
}

class MapPoint {
  final String id; final String name; final MapPointKind kind; final double lat; final double lng; final String? notes; final String? color; final MapPointVisibility visibility; final String? huntingUnitId;
  const MapPoint({required this.id, required this.name, required this.kind, required this.lat, required this.lng, this.notes, this.color, required this.visibility, this.huntingUnitId});
  LatLng get position => LatLng(lat, lng);
  factory MapPoint.fromJson(Map<String, dynamic> json) => MapPoint(id: json['id'] as String, name: json['name'] as String? ?? '', kind: MapPointKind.parse(json['kind'] as String?), lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble(), notes: json['notes'] as String?, color: json['color'] as String?, visibility: MapPointVisibility.parse(json['visibility'] as String?), huntingUnitId: json['hunting_unit_id'] as String?);
}

class SharedPoint extends MapPoint {
  final MapOwner owner;
  const SharedPoint({required super.id, required super.name, required super.kind, required super.lat, required super.lng, super.color, required super.visibility, required this.owner}) : super(notes: null);
  factory SharedPoint.fromJson(Map<String, dynamic> json) => SharedPoint(id: json['id'] as String, name: json['name'] as String? ?? '', kind: MapPointKind.parse(json['kind'] as String?), lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble(), color: json['color'] as String?, visibility: MapPointVisibility.parse(json['visibility'] as String?), owner: MapOwner.fromJson(Map<String, dynamic>.from(json['owner'] as Map? ?? const {})));
}

class MapOuting {
  final String id; final String? title; final String? zoneName; final DateTime startedAt; final int harvestTotal; final double lat; final double lng;
  const MapOuting({required this.id, this.title, this.zoneName, required this.startedAt, required this.harvestTotal, required this.lat, required this.lng});
  LatLng get position => LatLng(lat, lng);
  factory MapOuting.fromJson(Map<String, dynamic> json) => MapOuting(id: (json['log_id'] ?? json['id']) as String, title: json['title'] as String?, zoneName: json['zone_name'] as String?, startedAt: DateTime.parse(json['started_at'] as String).toUtc(), harvestTotal: (json['harvest_total'] as num?)?.toInt() ?? 0, lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble());
}

class UnitArea {
  final String id; final String name; final String unitType; final String? code; final double? areaM2; final String? regionId; final String? regionName; final List<List<LatLng>> rings;
  const UnitArea({required this.id, required this.name, required this.unitType, this.code, this.areaM2, this.regionId, this.regionName, required this.rings});
  LatLng? get center { final points = rings.expand((ring) => ring).toList(); if (points.isEmpty) return null; return LatLng(points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length, points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length); }
  factory UnitArea.fromJson(Map<String, dynamic> json) => UnitArea(id: (json['unit_id'] ?? json['id']) as String, name: json['name'] as String? ?? '', unitType: json['unit_type'] as String? ?? '', code: json['code'] as String?, areaM2: (json['area_m2'] as num?)?.toDouble(), regionId: json['region_id'] as String?, regionName: json['region_name'] as String?, rings: _geoJsonRings(json['geojson']));
}

class MapZone {
  final String id; final String name; final String? notes; final MapPointVisibility visibility; final String? color; final double areaM2; final double minLat; final double minLng; final double maxLat; final double maxLng; final Map<String, dynamic> geoJson; final List<List<LatLng>> rings;
  const MapZone({required this.id, required this.name, this.notes, required this.visibility, this.color, required this.areaM2, required this.minLat, required this.minLng, required this.maxLat, required this.maxLng, required this.geoJson, required this.rings});
  LatLng get center => LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  factory MapZone.fromJson(Map<String, dynamic> json) {
    final raw = json['geojson'];
    final geoJson = Map<String, dynamic>.from((raw is String ? jsonDecode(raw) : raw) as Map? ?? const {});
    final rings = _geoJsonRings(geoJson);
    final points = rings.expand((ring) => ring).toList();
    double fallback(bool latitude, bool maximum) {
      if (points.isEmpty) return 0;
      final values = points.map((point) => latitude ? point.latitude : point.longitude);
      return maximum ? values.reduce((a, b) => a > b ? a : b) : values.reduce((a, b) => a < b ? a : b);
    }
    return MapZone(id: json['id'] as String, name: json['name'] as String? ?? '', notes: json['notes'] as String?, visibility: MapPointVisibility.parse(json['visibility'] as String?), color: json['color'] as String?, areaM2: (json['area_m2'] as num?)?.toDouble() ?? 0, minLat: (json['min_lat'] as num?)?.toDouble() ?? fallback(true, false), minLng: (json['min_lng'] as num?)?.toDouble() ?? fallback(false, false), maxLat: (json['max_lat'] as num?)?.toDouble() ?? fallback(true, true), maxLng: (json['max_lng'] as num?)?.toDouble() ?? fallback(false, true), geoJson: geoJson, rings: rings);
  }
}

class SharedZone extends MapZone {
  final MapOwner owner;
  const SharedZone({required super.id, required super.name, required super.visibility, super.color, required super.areaM2, required super.minLat, required super.minLng, required super.maxLat, required super.maxLng, required super.geoJson, required super.rings, required this.owner}) : super(notes: null);
  factory SharedZone.fromJson(Map<String, dynamic> json) {
    final zone = MapZone.fromJson(json);
    return SharedZone(id: zone.id, name: zone.name, visibility: zone.visibility, color: zone.color, areaM2: zone.areaM2, minLat: zone.minLat, minLng: zone.minLng, maxLat: zone.maxLat, maxLng: zone.maxLng, geoJson: zone.geoJson, rings: zone.rings, owner: MapOwner.fromJson(Map<String, dynamic>.from(json['owner'] as Map? ?? const {})));
  }
}

List<List<LatLng>> _geoJsonRings(Object? value) {
  final object = value is String ? jsonDecode(value) : value;
  if (object is! Map) return const [];
  final json = Map<String, dynamic>.from(object);
  final coordinates = json['coordinates'];
  if (coordinates is! List) return const [];
  Iterable<List> raw = json['type'] == 'MultiPolygon' ? coordinates.whereType<List>().expand((polygon) => polygon.whereType<List>()) : coordinates.whereType<List>();
  return raw.map((ring) => ring.whereType<List>().where((item) => item.length >= 2).map((item) => LatLng((item[1] as num).toDouble(), (item[0] as num).toDouble())).toList()).where((ring) => ring.length >= 3).toList();
}

List<List<LatLng>> geoJsonRings(Object? value) => _geoJsonRings(value);

class MapPost {
  final String id; final String kind; final String? content; final String? locationName; final double lat; final double lng; final DateTime createdAt; final int reactionCount; final int commentCount; final MapOwner author; final String? mediaPath;
  const MapPost({required this.id, required this.kind, this.content, this.locationName, required this.lat, required this.lng, required this.createdAt, required this.reactionCount, required this.commentCount, required this.author, this.mediaPath});
  LatLng get position => LatLng(lat, lng);
  factory MapPost.fromJson(Map<String, dynamic> json) => MapPost(id: json['id'] as String, kind: json['kind'] as String? ?? 'checkin', content: json['content'] as String?, locationName: json['location_name'] as String?, lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble(), createdAt: DateTime.parse(json['created_at'] as String).toUtc(), reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0, commentCount: (json['comment_count'] as num?)?.toInt() ?? 0, author: MapOwner.fromJson(Map<String, dynamic>.from(json['author'] as Map? ?? const {})), mediaPath: json['media_path'] as String?);
}

class MapEvent {
  final String id; final String title; final DateTime startsAt; final double lat; final double lng; final String category; final String? locationName; final int attendeeCount; final int? distanceM;
  const MapEvent({required this.id, required this.title, required this.startsAt, required this.lat, required this.lng, required this.category, this.locationName, required this.attendeeCount, this.distanceM});
  LatLng get position => LatLng(lat, lng);
  factory MapEvent.fromJson(Map<String, dynamic> json) => MapEvent(id: json['id'] as String, title: json['title'] as String? ?? '', startsAt: DateTime.parse(json['starts_at'] as String).toUtc(), lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble(), category: json['category'] as String? ?? '', locationName: json['location_name'] as String?, attendeeCount: (json['attendee_count'] as num?)?.toInt() ?? 0, distanceM: (json['distance_m'] as num?)?.toInt());
}

class UnitAtPoint {
  final String id; final String name; final String unitType; final String? code; final String? regionId; final String? regionName;
  const UnitAtPoint({required this.id, required this.name, required this.unitType, this.code, this.regionId, this.regionName});
  factory UnitAtPoint.fromJson(Map<String, dynamic> json) => UnitAtPoint(id: json['unit_id'] as String, name: json['name'] as String? ?? '', unitType: json['unit_type'] as String? ?? '', code: json['code'] as String?, regionId: json['region_id'] as String?, regionName: json['region_name'] as String?);
}

class MapOverview {
  final List<MapPoint> myPoints; final List<SharedPoint> sharedPoints; final List<MapZone> myZones; final List<SharedZone> sharedZones; final List<MapOuting> outings; final List<UnitArea> units; final List<MapPost> posts; final List<MapEvent> events; final List<OfficialMapLayer> layers;
  const MapOverview({required this.myPoints, required this.sharedPoints, required this.myZones, required this.sharedZones, required this.outings, required this.units, required this.posts, required this.events, required this.layers});
  factory MapOverview.fromJson(Map<String, dynamic> json) => MapOverview(myPoints: _list(json, 'my_points', MapPoint.fromJson), sharedPoints: _list(json, 'shared_points', SharedPoint.fromJson), myZones: _list(json, 'my_zones', MapZone.fromJson), sharedZones: _list(json, 'shared_zones', SharedZone.fromJson), outings: _list(json, 'my_outings', MapOuting.fromJson), units: _list(json, 'units', UnitArea.fromJson), posts: _list(json, 'posts', MapPost.fromJson), events: _list(json, 'events', MapEvent.fromJson), layers: _list(json, 'layers', OfficialMapLayer.fromJson));
  static List<T> _list<T>(Map<String, dynamic> json, String key, T Function(Map<String, dynamic>) parse) => (json[key] as List? ?? const []).whereType<Map>().map((item) => parse(Map<String, dynamic>.from(item))).toList();
}

class OfficialMapLayer {
  final String id, kind, name, color, countryCode;
  final String? description, sourceName, sourceUrl, regionId;
  final int featureCount;
  final double areaM2;
  final DateTime updatedAt;
  const OfficialMapLayer({required this.id, required this.kind, required this.name, required this.color, required this.countryCode, this.description, this.sourceName, this.sourceUrl, this.regionId, required this.featureCount, required this.areaM2, required this.updatedAt});
  factory OfficialMapLayer.fromJson(Map<String, dynamic> json) => OfficialMapLayer(id: json['id'].toString(), kind: json['kind']?.toString() ?? 'other', name: json['name']?.toString() ?? '', color: json['color']?.toString() ?? '', countryCode: json['country_code']?.toString() ?? '', description: json['description']?.toString(), sourceName: json['source_name']?.toString(), sourceUrl: json['source_url']?.toString(), regionId: json['region_id']?.toString(), featureCount: (json['feature_count'] as num?)?.toInt() ?? 0, areaM2: (json['area_m2'] as num?)?.toDouble() ?? 0, updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0));
}

class OfficialMapFeature {
  final String? name, code;
  final List<List<LatLng>> rings;
  const OfficialMapFeature({this.name, this.code, required this.rings});
}

class OfficialLayerGeometry {
  final List<OfficialMapFeature> features;
  const OfficialLayerGeometry(this.features);
  factory OfficialLayerGeometry.fromJson(Map<String, dynamic> json) {
    final values = json['type'] == 'FeatureCollection' ? json['features'] as List? ?? const [] : [json];
    return OfficialLayerGeometry([for (final raw in values) if (raw is Map) () { final feature = Map<String, dynamic>.from(raw); final properties = feature['properties'] as Map? ?? const {}; return OfficialMapFeature(name: properties['name']?.toString(), code: properties['code']?.toString(), rings: geoJsonRings(feature['geometry'] ?? feature)); }()]);
  }
}

class OfficialFeatureSelection {
  final OfficialMapLayer layer;
  final OfficialMapFeature feature;
  const OfficialFeatureSelection(this.layer, this.feature);
}