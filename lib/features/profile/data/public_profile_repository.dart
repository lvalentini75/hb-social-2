import 'package:hb_social/features/profile/domain/user_profile.dart';

/// Read access to public profiles by username. The only implementation
/// until P03/P04 is [EmptyPublicProfileRepository]; a Supabase-backed
/// implementation replaces it once the `profiles` table exists.
abstract class PublicProfileRepository {
  Future<UserProfile?> byUsername(String username);
}
