import 'package:hb_social/features/forum/data/forum_repository.dart';
import 'package:hb_social/features/forum/domain/forum_thread.dart';

/// No backend yet (see `docs/DECISIONS.md`): every query resolves to an
/// empty list rather than any sample/mock thread.
class EmptyForumRepository implements ForumRepository {
  const EmptyForumRepository();

  @override
  Future<List<ForumThread>> latest() async => const [];
}
