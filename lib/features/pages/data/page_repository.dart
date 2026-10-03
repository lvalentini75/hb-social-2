import 'package:hb_social/features/pages/domain/community_page.dart';

/// Read access to community pages. The only implementation until P03/P04 is
/// [EmptyPageRepository]; a Supabase-backed implementation replaces it once
/// the `pages` table exists.
abstract class PageRepository {
  Future<List<CommunityPage>> discover();
}
