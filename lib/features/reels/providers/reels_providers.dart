import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/reels/data/reels_repository.dart';
import 'package:hb_social/features/reels/domain/reel.dart';

final reelsRepositoryProvider = Provider<ReelsRepository>((ref) => ReelsRepository(ref.watch(supabaseClientProvider)));
final reelUploadAllowanceProvider = FutureProvider<ReelUploadAllowance>((ref) => ref.watch(reelsRepositoryProvider).uploadAllowed());
final reelDetailProvider = FutureProvider.family<Reel, String>((ref, id) => ref.watch(reelsRepositoryProvider).detail(id));
final reelInsightsProvider = FutureProvider.family<ReelInsights, String>((ref, id) => ref.watch(reelsRepositoryProvider).insights(id));
final reelsByUserProvider = FutureProvider.family<List<Reel>, String>((ref, id) => ref.watch(reelsRepositoryProvider).byUser(id));
final adminReelsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) => ref.watch(reelsRepositoryProvider).adminStats());
final reelsFeedProvider = AsyncNotifierProvider<ReelsFeedNotifier, ReelsFeedState>(ReelsFeedNotifier.new);
final myReelsProvider = AsyncNotifierProvider<MyReelsNotifier, List<ReelVideo>>(MyReelsNotifier.new);

class ReelsFeedState {
  final List<Reel> items;
  final bool seenPhase;
  final bool hasMore;
  final bool loadingMore;
  const ReelsFeedState({this.items = const [], this.seenPhase = false, this.hasMore = true, this.loadingMore = false});
  ReelsFeedState copyWith({List<Reel>? items, bool? seenPhase, bool? hasMore, bool? loadingMore}) => ReelsFeedState(items: items ?? this.items, seenPhase: seenPhase ?? this.seenPhase, hasMore: hasMore ?? this.hasMore, loadingMore: loadingMore ?? this.loadingMore);
}

class ReelsFeedNotifier extends AsyncNotifier<ReelsFeedState> {
  static const _limit = 20;
  @override Future<ReelsFeedState> build() async {
    final country = ref.watch(userSettingsProvider).countryCode;
    final items = await ref.watch(reelsRepositoryProvider).feed(country: country, limit: _limit);
    return ReelsFeedState(items: items, seenPhase: items.length < _limit, hasMore: items.isNotEmpty);
  }
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    var seen = current.seenPhase;
    final last = current.items.lastOrNull;
    var next = await ref.read(reelsRepositoryProvider).feed(country: ref.read(userSettingsProvider).countryCode, limit: _limit, beforeCreatedAt: last?.createdAt, beforeId: last?.postId, seen: seen);
    if (!seen && next.length < _limit) {
      seen = true;
      if (next.isEmpty) next = await ref.read(reelsRepositoryProvider).feed(country: ref.read(userSettingsProvider).countryCode, limit: _limit, seen: true);
    }
    final ids = current.items.map((item) => item.postId).toSet();
    state = AsyncData(ReelsFeedState(items: [...current.items, ...next.where((item) => ids.add(item.postId))], seenPhase: seen, hasMore: next.isNotEmpty, loadingMore: false));
  }
  Future<void> review() async {
    final items = await ref.read(reelsRepositoryProvider).feed(country: ref.read(userSettingsProvider).countryCode, limit: _limit, seen: true);
    state = AsyncData(ReelsFeedState(items: items, seenPhase: true, hasMore: items.isNotEmpty));
  }
}

class MyReelsNotifier extends AsyncNotifier<List<ReelVideo>> {
  Timer? _timer;
  DateTime? _pollStarted;
  @override Future<List<ReelVideo>> build() async {
    ref.onDispose(() => _timer?.cancel());
    final items = await ref.watch(reelsRepositoryProvider).myVideos();
    _schedule(items);
    return items;
  }
  Future<void> refreshNow() async {
    final current = state.value ?? const <ReelVideo>[];
    final processing = current.where((item) => item.processing).toList();
    for (final item in processing) { await ref.read(reelsRepositoryProvider).refresh(item.id); }
    final items = await ref.read(reelsRepositoryProvider).myVideos();
    state = AsyncData(items);
    _schedule(items);
  }
  void _schedule(List<ReelVideo> items) {
    _timer?.cancel();
    if (!items.any((item) => item.processing)) { _pollStarted = null; return; }
    _pollStarted ??= DateTime.now();
    if (DateTime.now().difference(_pollStarted!) >= const Duration(minutes: 10)) return;
    _timer = Timer(const Duration(seconds: 10), refreshNow);
  }
}