import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/profile/data/public_profile_repository.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>(
  (ref) => SupabasePublicProfileRepository(ref.watch(supabaseClientProvider)),
);

/// The public profile for a given username, or null when it doesn't exist.
final publicProfileProvider = FutureProvider.autoDispose.family<UserProfile?, String>((ref, username) async {
  final repository = ref.watch(publicProfileRepositoryProvider);
  return repository.byUsername(username);
});
