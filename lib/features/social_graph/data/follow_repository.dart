import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowRepository {
  final SupabaseClient _client;

  const FollowRepository(this._client);

  Future<bool> isFollowing(String userId) async {
    try {
      final currentId = _client.auth.currentUser?.id;
      if (currentId == null) return false;
      final row = await _client.from('follows').select('id').eq('follower_id', currentId).eq('following_id', userId).maybeSingle();
      return row != null;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> follow(String userId) async {
    try {
      final currentId = _client.auth.currentUser?.id;
      if (currentId == null) throw const AuthException('Not authenticated');
      await _client.from('follows').upsert({'follower_id': currentId, 'following_id': userId}, onConflict: 'follower_id,following_id');
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> unfollow(String userId) async {
    try {
      final currentId = _client.auth.currentUser?.id;
      if (currentId == null) throw const AuthException('Not authenticated');
      await _client.from('follows').delete().eq('follower_id', currentId).eq('following_id', userId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}