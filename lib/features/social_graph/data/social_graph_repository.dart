import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/onboarding/domain/suggestion.dart';
import 'package:hb_social/features/social_graph/domain/social_connection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialGraphRepository {
  static const connectionPageSize = 20;
  final SupabaseClient _client;

  const SocialGraphRepository(this._client);

  Future<RelationshipStatus> relationshipWith(String userId) async {
    try {
      final rows = await _client.rpc('relationship_with', params: {'p_user': userId});
      return RelationshipStatus.fromJson(Map<String, dynamic>.from((rows as List).first as Map));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String> sendRequest(String userId, String? message) async {
    try {
      final rows = await _client.rpc('send_friend_request', params: {'p_user': userId, 'p_message': message});
      return Map<String, dynamic>.from((rows as List).first as Map)['status'] as String;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<bool> respond(String requestId, bool accept) async {
    try {
      final rows = await _client.rpc('respond_friend_request', params: {'p_request_id': requestId, 'p_accept': accept});
      return Map<String, dynamic>.from((rows as List).first as Map)['is_friend'] as bool? ?? false;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> cancel(String requestId) async {
    try {
      await _client.rpc('cancel_friend_request', params: {'p_request_id': requestId});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> removeFriend(String userId) async {
    try {
      await _client.rpc('remove_friend', params: {'p_user': userId});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Page<SocialConnection>> followers(String userId, PageCursor? cursor) => _connections(userId: userId, followers: true, cursor: cursor);
  Future<Page<SocialConnection>> following(String userId, PageCursor? cursor) => _connections(userId: userId, followers: false, cursor: cursor);

  Future<Page<SocialConnection>> _connections({required String userId, required bool followers, PageCursor? cursor}) async {
    try {
      final relation = followers ? 'follower' : 'following';
      final relationId = followers ? 'follower_id' : 'following_id';
      var query = _client.from('follows').select('id,created_at,$relation:user_profiles!$relationId(id,username,display_name,avatar_url,verification_level,verified_at,last_seen_at)').eq(followers ? 'following_id' : 'follower_id', userId);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(connectionPageSize);
      final items = (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final profileJson = Map<String, dynamic>.from(row[relation] as Map);
        profileJson['avatar_url'] = storagePublicUrl(_client, 'avatars', profileJson['avatar_url'] as String?);
        return SocialConnection(id: row['id'] as String, createdAt: DateTime.parse(row['created_at'] as String).toUtc(), profile: SocialProfile.fromJson(profileJson));
      }).toList();
      final last = items.length == connectionPageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<FriendProfile>> friends(String userId, int offset) async {
    try {
      final rows = await _client.rpc('list_friends', params: {'p_user_id': userId, 'p_limit': 50, 'p_offset': offset});
      return (rows as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
        return FriendProfile.fromJson(json);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<FriendRequest>> requests({required bool received}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const [];
      final relation = received ? 'requester' : 'addressee';
      final relationId = received ? 'requester_id' : 'addressee_id';
      final filter = received ? 'addressee_id' : 'requester_id';
      final rows = await _client.from('friend_requests').select('id,message,created_at,$relation:user_profiles!$relationId(id,username,display_name,avatar_url,verification_level,verified_at,last_seen_at)').eq(filter, userId).eq('status', 'pending').order('created_at', ascending: false);
      return (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final profileJson = Map<String, dynamic>.from(row[relation] as Map);
        profileJson['avatar_url'] = storagePublicUrl(_client, 'avatars', profileJson['avatar_url'] as String?);
        return FriendRequest(id: row['id'] as String, message: row['message'] as String?, createdAt: DateTime.parse(row['created_at'] as String).toUtc(), profile: SocialProfile.fromJson(profileJson));
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<int> pendingReceivedCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;
      final response = await _client.from('friend_requests').select('id').eq('addressee_id', userId).eq('status', 'pending').count(CountOption.exact);
      return response.count;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<SuggestedProfile>> suggestions({int limit = 30}) async {
    try {
      final rows = await _client.rpc('suggest_profiles', params: {'p_limit': limit});
      return (rows as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
        return SuggestedProfile.fromJson(json);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}