import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/diary/data/diary_media_url_service.dart';
import 'package:hb_social/features/diary/data/diary_repository.dart';
import 'package:hb_social/features/diary/domain/diary_season.dart';
import 'package:hb_social/features/diary/domain/diary_season_stats.dart';
import 'package:hb_social/features/diary/domain/outing.dart';

typedef OutingsRequest = ({String? userId, String? season});
typedef DiaryStatsRequest = ({String? userId, String? season});

class OutingsState {
  final List<Outing> items;
  final bool hasMore;
  final bool loadingMore;
  const OutingsState({required this.items, required this.hasMore, this.loadingMore = false});
  OutingsState copyWith({List<Outing>? items, bool? hasMore, bool? loadingMore}) => OutingsState(items: items ?? this.items, hasMore: hasMore ?? this.hasMore, loadingMore: loadingMore ?? this.loadingMore);
}

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) => DiaryRepository(ref.watch(supabaseClientProvider)));
final diaryMediaUrlServiceProvider = Provider<DiaryMediaUrlService>((ref) => DiaryMediaUrlService(ref.watch(supabaseClientProvider)));
final diarySeasonsProvider = FutureProvider.autoDispose.family<List<DiarySeason>, String?>((ref, userId) => ref.watch(diaryRepositoryProvider).seasons(userId: userId));
final diaryStatsProvider = FutureProvider.autoDispose.family<DiarySeasonStats, DiaryStatsRequest>((ref, request) => ref.watch(diaryRepositoryProvider).seasonStats(userId: request.userId, season: request.season));
final diaryExportOutingsProvider = FutureProvider.autoDispose.family<List<Outing>, DiaryStatsRequest>((ref, request) async {
  final stats = await ref.watch(diaryStatsProvider(request).future);
  return ref.watch(diaryRepositoryProvider).listAllOutings(userId: request.userId, season: stats.seasonLabel);
});
final outingProvider = FutureProvider.autoDispose.family<Outing?, String>((ref, id) => ref.watch(diaryRepositoryProvider).getOuting(id, locale: ref.watch(userSettingsProvider).locale.languageCode));
final diaryCurrentSeasonProvider = FutureProvider.autoDispose<String>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return ref.watch(diaryRepositoryProvider).seasonLabel(DateTime.now(), settings.countryCode ?? 'IT');
});
final outingsProvider = AsyncNotifierProvider.autoDispose.family<OutingsNotifier, OutingsState, OutingsRequest>((request) => OutingsNotifier(request));
final diaryCoversProvider = FutureProvider.autoDispose.family<Map<String, String>, List<Outing>>((ref, items) => ref.watch(diaryMediaUrlServiceProvider).createSignedUrls(items.expand((item) => [item.coverThumbnailPath ?? item.coverPath])));
final todayOutingProvider = FutureProvider.autoDispose<Outing?>((ref) async {
  final season = await ref.watch(diaryCurrentSeasonProvider.future);
  final items = await ref.watch(diaryRepositoryProvider).listOutings(season: season);
  final now = DateTime.now();
  return items.where((item) { final day = item.startedAt.toLocal(); return day.year == now.year && day.month == now.month && day.day == now.day; }).firstOrNull;
});

class OutingsNotifier extends AsyncNotifier<OutingsState> {
  final OutingsRequest request;
  OutingsNotifier(this.request);
  @override
  Future<OutingsState> build() async {
    final items = await ref.watch(diaryRepositoryProvider).listOutings(userId: request.userId, season: request.season);
    return OutingsState(items: items, hasMore: items.length == 20);
  }
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref.read(diaryRepositoryProvider).listOutings(userId: request.userId, season: request.season, offset: current.items.length);
      state = AsyncData(OutingsState(items: [...current.items, ...next], hasMore: next.length == 20));
    } catch (error, stack) { state = AsyncError(error, stack); }
  }
}

class OutingFormState {
  final Outing? source;
  final bool duplicate;
  final DateTime? startedAt;
  final String? municipalityId;
  const OutingFormState({this.source, this.duplicate = false, this.startedAt, this.municipalityId});
}

class OutingFormNotifier extends Notifier<OutingFormState> {
  @override
  OutingFormState build() => const OutingFormState();
  void setSource(Outing? source, {bool duplicate = false}) => state = OutingFormState(source: source, duplicate: duplicate);
  void setPrefill({required DateTime startedAt, String? municipalityId}) => state = OutingFormState(startedAt: startedAt, municipalityId: municipalityId);
  void clear() => state = const OutingFormState();
}

final outingFormProvider = NotifierProvider<OutingFormNotifier, OutingFormState>(OutingFormNotifier.new);