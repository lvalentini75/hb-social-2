import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_p44_repository.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';

final adminP44RepositoryProvider = Provider<AdminP44Repository>((ref) => AdminP44Repository(ref.watch(supabaseClientProvider)));
final adminCalendarStatsProvider = FutureProvider.autoDispose.family<AdminCalendarsStats, String?>((ref, country) => ref.watch(adminP44RepositoryProvider).calendarStats(country));

typedef AdminCalendarFilter = ({String? country, String? regionId, String? season, String? status, String? speciesId, String query, int offset});
final adminP44CalendarsProvider = FutureProvider.autoDispose.family<List<AdminCalendarRowP44>, AdminCalendarFilter>((ref, filter) => ref.watch(adminP44RepositoryProvider).calendars(country: filter.country, regionId: filter.regionId, season: filter.season, status: filter.status, speciesId: filter.speciesId, query: filter.query, offset: filter.offset));

typedef AdminSpeciesFilter = ({String query, String? category, int offset});
final adminP44SpeciesProvider = FutureProvider.autoDispose.family<List<AdminSpeciesP44>, AdminSpeciesFilter>((ref, filter) => ref.watch(adminP44RepositoryProvider).species(query: filter.query, category: filter.category, offset: filter.offset));

typedef AdminLayerFilter = ({String? country, String? regionId, String? status});
final adminP44MapLayersProvider = FutureProvider.autoDispose.family<List<AdminMapLayerP44>, AdminLayerFilter>((ref, filter) => ref.watch(adminP44RepositoryProvider).mapLayers(country: filter.country, regionId: filter.regionId, status: filter.status));