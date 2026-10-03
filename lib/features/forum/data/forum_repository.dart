import 'package:hb_social/features/forum/domain/forum_thread.dart';

/// Read access to forum threads. The only implementation until P03/P04 is
/// [EmptyForumRepository]; a Supabase-backed implementation replaces it once
/// the `forum_threads` table exists.
abstract class ForumRepository {
  Future<List<ForumThread>> latest();
}
