import 'package:hb_social/features/pages/data/page_repository.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';

/// No backend yet (see `docs/DECISIONS.md`): every query resolves to an
/// empty list rather than any sample/mock page.
class EmptyPageRepository implements PageRepository {
  const EmptyPageRepository();

  @override
  Future<List<CommunityPage>> discover() async => const [];
}
