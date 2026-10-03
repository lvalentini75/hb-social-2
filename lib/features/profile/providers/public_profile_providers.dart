import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/profile/data/empty_public_profile_repository.dart';
import 'package:hb_social/features/profile/data/public_profile_repository.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

/// Swap this override once a Supabase-backed [PublicProfileRepository] exists (P03/P04).
final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((ref) => const EmptyPublicProfileRepository());

/// The public profile for a given username, or null when it doesn't exist.
/// Always null until P03/P04; the UI already renders loading, error and
/// not-found states for this provider.
final publicProfileProvider = FutureProvider.autoDispose.family<UserProfile?, String>((ref, username) async {
  final repository = ref.watch(publicProfileRepositoryProvider);
  return repository.byUsername(username);
});
