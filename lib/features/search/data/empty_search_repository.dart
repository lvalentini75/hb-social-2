import 'package:hb_social/features/search/data/search_repository.dart';
import 'package:hb_social/features/search/domain/search_result.dart';

/// No backend yet (see `docs/DECISIONS.md`): every query resolves to an
/// empty list rather than any sample/mock result.
class EmptySearchRepository implements SearchRepository {
  const EmptySearchRepository();

  @override
  Future<List<SearchResult>> search({required String query, required SearchCategory category}) async => const [];
}
