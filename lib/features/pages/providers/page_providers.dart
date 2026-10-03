import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/pages/data/empty_page_repository.dart';
import 'package:hb_social/features/pages/data/page_repository.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';

/// Swap this override once a Supabase-backed [PageRepository] exists (P03/P04).
final pageRepositoryProvider = Provider<PageRepository>((ref) => const EmptyPageRepository());

/// Selected visual filter. The repository remains empty until P03/P04.
final pagesFilterProvider = StateProvider<int>((ref) => 0);

/// Pages to discover. Always empty until P03/P04; the UI already renders
/// loading, error and empty states for this provider.
final pagesListProvider = FutureProvider.autoDispose<List<CommunityPage>>((ref) async {
  ref.watch(pagesFilterProvider);
  final repository = ref.watch(pageRepositoryProvider);
  return repository.discover();
});
