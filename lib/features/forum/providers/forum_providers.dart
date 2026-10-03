import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/forum/data/empty_forum_repository.dart';
import 'package:hb_social/features/forum/data/forum_repository.dart';
import 'package:hb_social/features/forum/domain/forum_thread.dart';

/// Swap this override once a Supabase-backed [ForumRepository] exists (P03/P04).
final forumRepositoryProvider = Provider<ForumRepository>((ref) => const EmptyForumRepository());

/// Selected visual filter. The repository remains empty until P03/P04.
final forumFilterProvider = StateProvider<int>((ref) => 0);

/// Latest forum threads. Always empty until P03/P04; the UI already renders
/// loading, error and empty states for this provider.
final forumThreadsProvider = FutureProvider.autoDispose<List<ForumThread>>((ref) async {
  ref.watch(forumFilterProvider);
  final repository = ref.watch(forumRepositoryProvider);
  return repository.latest();
});
