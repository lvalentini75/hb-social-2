import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/search/data/search_repository.dart';
import 'package:hb_social/features/search/domain/search_result.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) => SearchRepository(ref.watch(supabaseClientProvider)));

final searchOverviewProvider = FutureProvider.autoDispose.family<SearchOverview, String>((ref, query) async {
  final value = await ref.watch(searchRepositoryProvider).searchAll(query);
  if (ref.watch(firearmsShowcaseEnabledProvider)) return value;
  return SearchOverview({for (final entry in value.sections.entries) entry.key: entry.value.where((item) => item.category != SearchCategory.listings || item.extra['is_mediated'] != true).toList()});
});

final searchTypeProvider = FutureProvider.autoDispose.family<SearchPageResult, SearchRequest>((ref, request) async {
  final value = await ref.watch(searchRepositoryProvider).searchType(query: request.query, category: request.category, offset: request.offset);
  if (ref.watch(firearmsShowcaseEnabledProvider)) return value;
  return SearchPageResult(items: value.items.where((item) => item is! SearchCommunityResult || !item.isMediated).toList(), hasMore: value.hasMore);
});

final trendingHashtagsProvider = FutureProvider.autoDispose<List<SearchHashtag>>((ref) => ref.watch(searchRepositoryProvider).trendingHashtags());

final recentSearchesProvider = AsyncNotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

class RecentSearchesNotifier extends AsyncNotifier<List<String>> {
  SearchRepository get _repository => ref.read(searchRepositoryProvider);

  @override
  Future<List<String>> build() => _repository.recentQueries();

  Future<void> add(String query) async => state = AsyncData(await _repository.saveRecent(query));
  Future<void> remove(String query) async => state = AsyncData(await _repository.removeRecent(query));

  Future<void> clear() async {
    await _repository.clearRecent();
    state = const AsyncData([]);
  }
}