import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  const ProfileRepository(this._client);

  Future<UserProfile> getMyProfile(String userId) async {
    try {
      final json = await _client.from('user_profiles').select().eq('id', userId).single();
      return UserProfile.fromJson(json);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<UserProfile> updateMyProfile(String userId, Map<String, dynamic> values) async {
    try {
      final json = await _client.from('user_profiles').update(values).eq('id', userId).select().single();
      return UserProfile.fromJson(json);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<bool> isUsernameAvailable(String username, {String? excludingUserId}) async {
    try {
      final rows = await _client.from('user_profiles').select('id').eq('username', username.trim().toLowerCase()).limit(1);
      return (rows as List).every((row) => row['id'] == excludingUserId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}