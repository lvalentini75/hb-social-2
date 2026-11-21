import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/sightings/data/sightings_repository.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/domain/sighting_alert.dart';

typedef MySightingsRequest = ({String? season, String? speciesId, String? logId});
typedef NearbySightingsRequest = ({double lat, double lng, double radiusKm, String? speciesId, int days});
typedef HeatmapRequest = ({double lat, double lng, double radiusKm, String? speciesId, int days});
typedef SpeciesActivityRequest = ({String? regionId, double? lat, double? lng, int days});

class SightingsState {
  final List<Sighting> items;
  final bool hasMore;
  final bool loadingMore;
  const SightingsState({required this.items, required this.hasMore, this.loadingMore = false});
  SightingsState copyWith({List<Sighting>? items, bool? hasMore, bool? loadingMore}) => SightingsState(items: items ?? this.items, hasMore: hasMore ?? this.hasMore, loadingMore: loadingMore ?? this.loadingMore);
}

final sightingsRepositoryProvider = Provider<SightingsRepository>((ref) => SightingsRepository(ref.watch(supabaseClientProvider), ref.watch(mediaUploadServiceProvider)));
final mySightingsProvider = AsyncNotifierProvider.autoDispose.family<MySightingsNotifier, SightingsState, MySightingsRequest>((request) => MySightingsNotifier(request));
final sightingDetailProvider = FutureProvider.autoDispose.family<SightingDetail, String>((ref, id) => ref.watch(sightingsRepositoryProvider).detail(id));
final sightingsOfProvider = AsyncNotifierProvider.autoDispose.family<SightingsOfNotifier, SightingsState, String>((userId) => SightingsOfNotifier(userId));
final nearbySightingsProvider = FutureProvider.autoDispose.family<List<NearbySighting>, NearbySightingsRequest>((ref, request) => ref.watch(sightingsRepositoryProvider).nearby(lat: request.lat, lng: request.lng, radiusKm: request.radiusKm, speciesId: request.speciesId, from: DateTime.now().subtract(Duration(days: request.days))));
final sightingsHeatmapProvider = FutureProvider.autoDispose.family<List<SightingHeatCell>, HeatmapRequest>((ref, request) => ref.watch(sightingsRepositoryProvider).heatmap(lat: request.lat, lng: request.lng, radiusKm: request.radiusKm, speciesId: request.speciesId, from: DateTime.now().subtract(Duration(days: request.days))));
final speciesActivityProvider = FutureProvider.autoDispose.family<List<SpeciesActivity>, SpeciesActivityRequest>((ref, request) => ref.watch(sightingsRepositoryProvider).speciesActivity(regionId: request.regionId, lat: request.lat, lng: request.lng, days: request.days));
final mySightingAlertsProvider = FutureProvider.autoDispose<List<SightingAlert>>((ref) => ref.watch(sightingsRepositoryProvider).myAlerts());
final sightingAlertPrefillProvider = StateProvider<SightingAlertPrefill?>((ref) => null);

void invalidateSightingAlerts(Ref ref) => ref.invalidate(mySightingAlertsProvider);

class MySightingsNotifier extends AsyncNotifier<SightingsState> {
  final MySightingsRequest request;
  MySightingsNotifier(this.request);
  @override
  Future<SightingsState> build() async { final items = await ref.watch(sightingsRepositoryProvider).mySightings(season: request.season, speciesId: request.speciesId, logId: request.logId); return SightingsState(items: items, hasMore: items.length == 20); }
  Future<void> loadMore() async { final current = state.value; if (current == null || !current.hasMore || current.loadingMore) return; state = AsyncData(current.copyWith(loadingMore: true)); try { final next = await ref.read(sightingsRepositoryProvider).mySightings(season: request.season, speciesId: request.speciesId, logId: request.logId, offset: current.items.length); state = AsyncData(SightingsState(items: [...current.items, ...next], hasMore: next.length == 20)); } catch (error, stack) { state = AsyncError(error, stack); } }
}

class SightingsOfNotifier extends AsyncNotifier<SightingsState> {
  final String userId;
  SightingsOfNotifier(this.userId);
  @override
  Future<SightingsState> build() async { final items = await ref.watch(sightingsRepositoryProvider).sightingsOf(userId); return SightingsState(items: items, hasMore: items.length == 20); }
  Future<void> loadMore() async { final current = state.value; if (current == null || !current.hasMore || current.loadingMore) return; state = AsyncData(current.copyWith(loadingMore: true)); try { final next = await ref.read(sightingsRepositoryProvider).sightingsOf(userId, offset: current.items.length); state = AsyncData(SightingsState(items: [...current.items, ...next], hasMore: next.length == 20)); } catch (error, stack) { state = AsyncError(error, stack); } }
}

void invalidateSightings(Ref ref, {String? id}) { ref.invalidate(mySightingsProvider); ref.invalidate(sightingsOfProvider); if (id != null) ref.invalidate(sightingDetailProvider(id)); }

class SightingFormPrefill {
  final String? logId;
  final DateTime? sightedAt;
  final double? lat;
  final double? lng;
  final double? accuracyM;
  final String? municipalityId;
  final String? speciesId;
  const SightingFormPrefill({this.logId, this.sightedAt, this.lat, this.lng, this.accuracyM, this.municipalityId, this.speciesId});
}

final sightingFormPrefillProvider = StateProvider<SightingFormPrefill?>((ref) => null);