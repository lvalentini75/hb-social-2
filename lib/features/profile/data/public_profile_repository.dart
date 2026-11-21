import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PublicProfileRepository {
  Future<UserProfile?> byUsername(String username);
}

class SupabasePublicProfileRepository implements PublicProfileRepository {
  final SupabaseClient _client;

  const SupabasePublicProfileRepository(this._client);

  @override
  Future<UserProfile?> byUsername(String username) async {
    try {
      final json = await _client.from('user_profiles').select().eq('username', username.trim().toLowerCase()).eq('status', 'active').maybeSingle();
      return json == null ? null : UserProfile.fromJson(json);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}
