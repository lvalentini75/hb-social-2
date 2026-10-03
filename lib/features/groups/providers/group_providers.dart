import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/groups/data/empty_group_repository.dart';
import 'package:hb_social/features/groups/data/group_repository.dart';
import 'package:hb_social/features/groups/domain/group.dart';

/// Swap this override once a Supabase-backed [GroupRepository] exists (P03/P04).
final groupRepositoryProvider = Provider<GroupRepository>((ref) => const EmptyGroupRepository());

/// Index into the Groups screen's filter chips (Tutti/Pubblici/Privati/I miei).
/// Purely cosmetic until real data exists: every filter resolves to the same
/// empty "Suggeriti per te" list.
final groupsFilterProvider = StateProvider<int>((ref) => 0);

/// "Suggeriti per te" section. Always empty until P03/P04; the UI already
/// renders loading, error and empty states for this provider.
final groupsListProvider = FutureProvider.autoDispose<List<Group>>((ref) {
  ref.watch(groupsFilterProvider);
  final repository = ref.watch(groupRepositoryProvider);
  return repository.discover();
});

/// "I miei gruppi" section.
final myGroupsProvider = FutureProvider.autoDispose<List<Group>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.myGroups();
});

/// A single group by id, used by the group detail page. Resolves to null
/// until P03/P04 (no group is ever found), which the detail page renders as
/// an explicit "group not found" state.
final groupByIdProvider = FutureProvider.autoDispose.family<Group?, String>((ref, id) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.fetchById(id);
});
