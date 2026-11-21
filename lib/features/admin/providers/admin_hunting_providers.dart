import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_hunting_repository.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';

final adminHuntingRepositoryProvider = Provider<AdminHuntingRepository>((ref) => AdminHuntingRepository(ref.watch(supabaseClientProvider)));
final adminHuntingReferencesProvider = FutureProvider.autoDispose<AdminHuntingReferenceData>((ref) => ref.watch(adminHuntingRepositoryProvider).references());
final adminHuntingCalendarsProvider = FutureProvider.autoDispose.family<List<AdminCalendarRecord>, ({String country, String? region, String? season, String? status, String search})>((ref, value) => ref.watch(adminHuntingRepositoryProvider).calendars(countryCode: value.country, regionId: value.region, season: value.season, status: value.status, search: value.search));
final adminHuntingCalendarProvider = FutureProvider.autoDispose.family<AdminCalendarRecord?, String>((ref, id) => ref.watch(adminHuntingRepositoryProvider).calendar(id));
final adminHuntingSpeciesProvider = FutureProvider.autoDispose<List<AdminSpeciesRecord>>((ref) => ref.watch(adminHuntingRepositoryProvider).species());
final adminHuntingUnitsProvider = FutureProvider.autoDispose.family<List<AdminHuntingUnit>, ({String country, String? region, String? type})>((ref, value) => ref.watch(adminHuntingRepositoryProvider).units(value.country, regionId: value.region, unitType: value.type));
final adminUnitBoundariesProvider = FutureProvider.autoDispose.family<List<AdminUnitBoundary>, ({String country, String? region})>((ref, value) => ref.watch(adminHuntingRepositoryProvider).unitBoundaries(value.country, regionId: value.region));
final adminHuntingRegionsProvider = FutureProvider.autoDispose.family<List<AdminHuntingRegion>, String>((ref, country) => ref.watch(adminHuntingRepositoryProvider).regions(country));