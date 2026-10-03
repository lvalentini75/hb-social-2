import 'package:hb_social/features/groups/data/group_repository.dart';
import 'package:hb_social/features/groups/domain/group.dart';

/// No backend yet (see `docs/DECISIONS.md`): every query resolves to an
/// empty list rather than any sample/mock group.
class EmptyGroupRepository implements GroupRepository {
  const EmptyGroupRepository();

  @override
  Future<List<Group>> discover() async => const [];

  @override
  Future<List<Group>> myGroups() async => const [];

  @override
  Future<Group?> fetchById(String id) async => null;
}
