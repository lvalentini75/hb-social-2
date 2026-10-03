import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/search/data/empty_search_repository.dart';
import 'package:hb_social/features/search/data/search_repository.dart';
import 'package:hb_social/features/search/domain/search_result.dart';

/// Swap this override once a Supabase-backed [SearchRepository] exists (P03/P04).
final searchRepositoryProvider = Provider<SearchRepository>((ref) => const EmptySearchRepository());

/// The text currently typed in the search field.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// The category filter currently selected.
final searchCategoryProvider = StateProvider<SearchCategory>((ref) => SearchCategory.all);

/// Results for the current query/category. Always empty until P03/P04; the
/// UI already renders loading, error and empty states for this provider.
final searchResultsProvider = FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);
  final repository = ref.watch(searchRepositoryProvider);
  return repository.search(query: query, category: category);
});
