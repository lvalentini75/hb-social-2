import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/map/data/map_repository.dart';
import 'package:hb_social/features/map/domain/map_models.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:latlong2/latlong.dart';

class MapViewport {
  final LatLng center; final double zoom; final double radiusKm; final int revision;
  const MapViewport({required this.center, required this.zoom, required this.radiusKm, this.revision = 0});
  MapViewport copyWith({LatLng? center, double? zoom, double? radiusKm, int? revision}) => MapViewport(center: center ?? this.center, zoom: zoom ?? this.zoom, radiusKm: radiusKm ?? this.radiusKm, revision: revision ?? this.revision);
}

class MapLayers {
  final bool myPoints, sharedPoints, myZones, sharedZones, outings, units, posts, events, sightings, sightingsHeat, sightingsMarkers;
  final String? sightingsSpeciesId; final int sightingsDays;
  const MapLayers({this.myPoints = true, this.sharedPoints = true, this.myZones = true, this.sharedZones = true, this.outings = true, this.units = true, required this.posts, this.events = true, this.sightings = true, this.sightingsHeat = true, this.sightingsMarkers = true, this.sightingsSpeciesId, this.sightingsDays = 90});
  MapLayers copyWith({bool? myPoints, bool? sharedPoints, bool? myZones, bool? sharedZones, bool? outings, bool? units, bool? posts, bool? events, bool? sightings, bool? sightingsHeat, bool? sightingsMarkers, String? sightingsSpeciesId, bool clearSightingsSpecies = false, int? sightingsDays}) => MapLayers(myPoints: myPoints ?? this.myPoints, sharedPoints: sharedPoints ?? this.sharedPoints, myZones: myZones ?? this.myZones, sharedZones: sharedZones ?? this.sharedZones, outings: outings ?? this.outings, units: units ?? this.units, posts: posts ?? this.posts, events: events ?? this.events, sightings: sightings ?? this.sightings, sightingsHeat: sightingsHeat ?? this.sightingsHeat, sightingsMarkers: sightingsMarkers ?? this.sightingsMarkers, sightingsSpeciesId: clearSightingsSpecies ? null : sightingsSpeciesId ?? this.sightingsSpeciesId, sightingsDays: sightingsDays ?? this.sightingsDays);
}

final mapRepositoryProvider = Provider<MapRepository>((ref) => MapRepository(ref.watch(supabaseClientProvider)));
final mapViewportProvider = StateProvider<MapViewport>((ref) => const MapViewport(center: LatLng(42.5, 12.5), zoom: 6, radiusKm: 300));
final mapLayersProvider = StateProvider<MapLayers>((ref) => MapLayers(posts: kIsWeb));
final officialMapLayerIdsProvider = StateProvider<Set<String>>((ref) => <String>{});
final officialMapLayerGeometryProvider = FutureProvider.family<OfficialLayerGeometry, OfficialMapLayer>((ref, layer) => ref.watch(mapRepositoryProvider).layerGeometry(layer));
final selectedMapItemProvider = StateProvider<Object?>((ref) => null);
final mapOverviewProvider = FutureProvider<MapOverview>((ref) { final viewport = ref.watch(mapViewportProvider); return ref.watch(mapRepositoryProvider).overview(lat: viewport.center.latitude, lng: viewport.center.longitude, radiusKm: viewport.radiusKm, force: viewport.revision > 0); });
final mapSightingsProvider = FutureProvider<List<NearbySighting>>((ref) { final viewport = ref.watch(mapViewportProvider); final layers = ref.watch(mapLayersProvider); if (!layers.sightings) return const []; return ref.watch(sightingsRepositoryProvider).nearby(lat: viewport.center.latitude, lng: viewport.center.longitude, radiusKm: viewport.radiusKm, speciesId: layers.sightingsSpeciesId, from: DateTime.now().subtract(Duration(days: layers.sightingsDays))); });
final mapSightingsHeatProvider = FutureProvider<List<SightingHeatCell>>((ref) { final viewport = ref.watch(mapViewportProvider); final layers = ref.watch(mapLayersProvider); if (!layers.sightings) return const []; return ref.watch(sightingsRepositoryProvider).heatmap(lat: viewport.center.latitude, lng: viewport.center.longitude, radiusKm: viewport.radiusKm, speciesId: layers.sightingsSpeciesId, from: DateTime.now().subtract(Duration(days: layers.sightingsDays))); });

void forceMapRefresh(WidgetRef ref) { final value = ref.read(mapViewportProvider); ref.read(mapViewportProvider.notifier).state = value.copyWith(revision: value.revision + 1); }