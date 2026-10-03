import 'package:hb_social/features/groups/domain/group.dart';

/// Read access to groups. The only implementation until P03/P04 is
/// [EmptyGroupRepository]; a Supabase-backed implementation replaces it once
/// the `groups` table exists.
abstract class GroupRepository {
  Future<List<Group>> discover();
  Future<List<Group>> myGroups();
  Future<Group?> fetchById(String id);
}
