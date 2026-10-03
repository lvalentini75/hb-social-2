import 'package:hb_social/features/search/domain/search_result.dart';

/// Cross-entity search. The only implementation until P03/P04 is
/// [EmptySearchRepository]; a Supabase-backed implementation replaces it
/// once the indexed tables exist.
abstract class SearchRepository {
  Future<List<SearchResult>> search({required String query, required SearchCategory category});
}
