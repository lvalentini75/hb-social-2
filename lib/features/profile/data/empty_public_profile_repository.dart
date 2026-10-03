import 'package:hb_social/features/profile/data/public_profile_repository.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

/// No backend yet (see `docs/DECISIONS.md`): every lookup resolves to null
/// rather than any sample/mock profile.
class EmptyPublicProfileRepository implements PublicProfileRepository {
  const EmptyPublicProfileRepository();

  @override
  Future<UserProfile?> byUsername(String username) async => null;
}
