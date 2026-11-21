import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/hunting/data/hunting_calendar_repository.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';

class HuntingOverviewRequest {
  final String regionId;
  final DateTime day;
  final String? appliesTo;
  final double? lat;
  final double? lng;
  const HuntingOverviewRequest(this.regionId, this.day, this.appliesTo, [this.lat, this.lng]);

  @override
  bool operator ==(Object other) => other is HuntingOverviewRequest && other.regionId == regionId && other.appliesTo == appliesTo && other.lat == lat && other.lng == lng && other.day.year == day.year && other.day.month == day.month && other.day.day == day.day;
  @override
  int get hashCode => Object.hash(regionId, appliesTo, lat, lng, day.year, day.month, day.day);
}

class HuntingContext {
  final String? regionId;
  final DateTime date;
  final String? appliesTo;
  final String? unitId;
  final double? lat;
  final double? lng;
  final String? municipalityId;
  final String? municipalityName;

  const HuntingContext({this.regionId, required this.date, this.appliesTo, this.unitId, this.lat, this.lng, this.municipalityId, this.municipalityName});
  HuntingContext copyWith({String? regionId, DateTime? date, String? appliesTo, bool clearAppliesTo = false, String? unitId, double? lat, double? lng, String? municipalityId, String? municipalityName, bool clearPosition = false}) => HuntingContext(regionId: regionId ?? this.regionId, date: date ?? this.date, appliesTo: clearAppliesTo ? null : appliesTo ?? this.appliesTo, unitId: unitId ?? this.unitId, lat: clearPosition ? null : lat ?? this.lat, lng: clearPosition ? null : lng ?? this.lng, municipalityId: clearPosition ? null : municipalityId ?? this.municipalityId, municipalityName: clearPosition ? null : municipalityName ?? this.municipalityName);
}

class HuntingContextNotifier extends StateNotifier<HuntingContext> {
  HuntingContextNotifier(super.state);
  void setRegion(String value) => state = state.copyWith(regionId: value);
  void setDate(DateTime value) => state = state.copyWith(date: value);
  void setAppliesTo(String? value) => state = state.copyWith(appliesTo: value, clearAppliesTo: value == null);
  void setPosition(double lat, double lng) => state = HuntingContext(regionId: state.regionId, date: state.date, appliesTo: state.appliesTo, unitId: state.unitId, lat: lat, lng: lng);
  void setPositionUnit(double lat, double lng, {String? regionId, String? unitId, String? unitType}) => state = HuntingContext(regionId: regionId ?? state.regionId, date: state.date, appliesTo: unitType?.toLowerCase() ?? state.appliesTo, unitId: unitId ?? state.unitId, lat: lat, lng: lng);
  void sync({required String? regionId, required String? unitId}) => state = HuntingContext(regionId: regionId, date: state.date, appliesTo: state.appliesTo, unitId: unitId, lat: state.lat, lng: state.lng, municipalityId: state.municipalityId, municipalityName: state.municipalityName);
  void setMunicipality(Municipality? value) => state = value == null ? state.copyWith(clearPosition: true) : HuntingContext(regionId: state.regionId, date: state.date, appliesTo: state.appliesTo, unitId: state.unitId, lat: value.lat, lng: value.lng, municipalityId: value.id, municipalityName: value.name);
}

final huntingRepositoryProvider = Provider<HuntingRepository>((ref) => HuntingRepository(ref.watch(supabaseClientProvider)));
final huntingDataUpdatedProvider = StateProvider.autoDispose.family<bool, String?>((ref, regionId) => false);
final _huntingVersionsProvider = Provider<_HuntingVersions>((ref) => _HuntingVersions());
final huntingDataVersionProvider = FutureProvider.autoDispose.family<String, String?>((ref, regionId) async {
  var active = true;
  final timer = Timer.periodic(const Duration(seconds: 60), (_) => ref.invalidateSelf());
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(() { active = false; timer.cancel(); lifecycle.dispose(); });
  final version = await ref.watch(huntingRepositoryProvider).dataVersion(regionId);
  final versions = ref.read(_huntingVersionsProvider);
  final previous = versions.values[regionId];
  versions.values[regionId] = version;
  if (previous != null && previous != version) {
    ref.invalidate(huntingOverviewProvider);
    ref.invalidate(huntingTodayProvider);
    ref.invalidate(huntingDayProvider);
    ref.invalidate(monthHuntingDaysProvider);
    ref.invalidate(nextChangesProvider);
    ref.invalidate(regionsWithCalendarsProvider);
    ref.read(huntingDataUpdatedProvider(regionId).notifier).state = true;
    Timer(const Duration(seconds: 2), () { if (active) ref.read(huntingDataUpdatedProvider(regionId).notifier).state = false; });
  }
  return version;
});

class _HuntingVersions { final Map<String?, String> values = {}; }
final huntingContextProvider = StateNotifierProvider<HuntingContextNotifier, HuntingContext>((ref) {
  final settings = ref.read(userSettingsProvider);
  final notifier = HuntingContextNotifier(HuntingContext(regionId: settings.regionId, date: DateTime.now(), unitId: settings.unitId));
  ref.listen(userSettingsProvider, (_, next) {
    notifier.sync(regionId: next.regionId, unitId: next.unitId);
    if (next.municipalityId == null) notifier.setMunicipality(null); else ref.read(referenceRepositoryProvider).getMunicipality(next.municipalityId!).then(notifier.setMunicipality);
  });
  if (settings.municipalityId != null) ref.read(referenceRepositoryProvider).getMunicipality(settings.municipalityId!).then(notifier.setMunicipality);
  ref.listen(selectedUnitTypeProvider, (_, next) => next.whenData((value) => notifier.setAppliesTo(value == 'atc' || value == 'ca' ? value : null)), fireImmediately: true);
  return notifier;
});
final huntingOverviewProvider = FutureProvider.family<HuntingOverview, HuntingOverviewRequest>((ref, request) async {
  final entries = await ref.watch(huntingRepositoryProvider).overview(regionId: request.regionId, day: request.day, appliesTo: request.appliesTo, lat: request.lat, lng: request.lng);
  final settings = ref.watch(userSettingsProvider);
  final regions = settings.countryCode == null ? const <ReferenceRegion>[] : await ref.watch(regionsProvider(settings.countryCode!).future);
  var regionName = regions.where((region) => region.id == request.regionId).firstOrNull?.name ?? '';
  if (regionName.isEmpty) regionName = (await ref.watch(huntingRepositoryProvider).regionsWithCalendars(settings.countryCode)).where((region) => region.regionId == request.regionId).firstOrNull?.name ?? '';
  return HuntingOverview(regionId: request.regionId, regionName: regionName, day: request.day, appliesTo: request.appliesTo, entries: entries);
});
final huntingTodayProvider = FutureProvider<HuntingOverview?>((ref) async {
  final value = ref.watch(huntingContextProvider);
  if (value.regionId == null) return null;
  return ref.watch(huntingOverviewProvider(HuntingOverviewRequest(value.regionId!, value.date, value.appliesTo, value.lat, value.lng)).future);
});
final regionsWithCalendarsProvider = FutureProvider<List<RegionCalendars>>((ref) async {
  final settings = ref.watch(userSettingsProvider);
  final rows = await ref.watch(huntingRepositoryProvider).regionsWithCalendars(settings.countryCode);
  if (settings.regionId == null || rows.any((item) => item.regionId == settings.regionId)) return rows;
  final regions = settings.countryCode == null ? const <ReferenceRegion>[] : await ref.watch(regionsProvider(settings.countryCode!).future);
  final own = regions.where((item) => item.id == settings.regionId).firstOrNull;
  return [if (own != null) RegionCalendars(regionId: own.id, countryCode: settings.countryCode ?? '', code: '', name: own.name, kind: own.kind, calendars: 0), ...rows];
});
final nextChangesProvider = FutureProvider.family<List<CalendarChange>, int>((ref, days) {
  final value = ref.watch(huntingContextProvider);
  if (value.regionId == null) return const <CalendarChange>[];
  return ref.watch(huntingRepositoryProvider).nextChanges(regionId: value.regionId!, from: value.date, days: days);
});

class HuntingDayRequest {
  final String speciesId;
  final DateTime day;
  const HuntingDayRequest(this.speciesId, this.day);
  @override
  bool operator ==(Object other) => other is HuntingDayRequest && other.speciesId == speciesId && other.day.year == day.year && other.day.month == day.month && other.day.day == day.day;
  @override
  int get hashCode => Object.hash(speciesId, day.year, day.month, day.day);
}

final huntingDayProvider = FutureProvider.family<HuntingDayInfo, HuntingDayRequest>((ref, request) {
  final value = ref.watch(huntingContextProvider);
  if (value.regionId == null) throw StateError('region_required');
  return ref.watch(huntingRepositoryProvider).huntingDay(regionId: value.regionId!, speciesId: request.speciesId, day: request.day, appliesTo: value.appliesTo, unitId: value.unitId, lat: value.lat, lng: value.lng);
});

final monthHuntingDaysProvider = FutureProvider.family<List<HuntingDayInfo>, HuntingDayRequest>((ref, request) async {
  final value = ref.watch(huntingContextProvider);
  if (value.regionId == null) return const [];
  final count = DateTime(request.day.year, request.day.month + 1, 0).day;
  return Future.wait([for (var day = 1; day <= count; day++) ref.watch(huntingRepositoryProvider).huntingDay(regionId: value.regionId!, speciesId: request.speciesId, day: DateTime(request.day.year, request.day.month, day), appliesTo: value.appliesTo, unitId: value.unitId, lat: value.lat, lng: value.lng)]);
});

final sunWeekProvider = FutureProvider<List<SunTimes>>((ref) {
  final value = ref.watch(huntingContextProvider);
  if (value.lat == null || value.lng == null) return const <SunTimes>[];
  return Future.wait([for (var index = 0; index < 7; index++) ref.watch(huntingRepositoryProvider).sunTimes(day: value.date.add(Duration(days: index)), lat: value.lat!, lng: value.lng!)]);
});

class HuntingSunDay {
  final SunTimes sun;
  final DateTime? opensAt;
  final DateTime? closesAt;
  const HuntingSunDay({required this.sun, this.opensAt, this.closesAt});
}

final huntingSunWeekProvider = FutureProvider<List<HuntingSunDay>>((ref) async {
  final value = ref.watch(huntingContextProvider);
  if (value.regionId == null || value.lat == null || value.lng == null) return const [];
  final repository = ref.watch(huntingRepositoryProvider);
  return Future.wait([for (var index = 0; index < 7; index++) () async { final day = value.date.add(Duration(days: index)); final results = await Future.wait<Object>([repository.sunTimes(day: day, lat: value.lat!, lng: value.lng!), repository.overview(regionId: value.regionId!, day: day, appliesTo: value.appliesTo, lat: value.lat, lng: value.lng)]); final entries = results[1] as List<CalendarDayInfo>; final timed = entries.where((entry) => entry.opensAt != null && entry.closesAt != null).firstOrNull; return HuntingSunDay(sun: results[0] as SunTimes, opensAt: timed?.opensAt, closesAt: timed?.closesAt); }()]);
});