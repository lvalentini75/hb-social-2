import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/onboarding/domain/suggestion.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestsRepository {
  final SupabaseClient _client;

  const InterestsRepository(this._client);

  Future<List<String>> getMine() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final rows = await _client.from('user_interests').select('interest').eq('user_id', userId).order('interest');
      return (rows as List).map((row) => row['interest'] as String).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> replaceMine(List<String> interests) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');
      await _client.from('user_interests').delete().eq('user_id', userId);
      if (interests.isNotEmpty) await _client.from('user_interests').insert(interests.map((interest) => {'user_id': userId, 'interest': interest}).toList());
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}

class SuggestionsRepository {
  final SupabaseClient _client;

  const SuggestionsRepository(this._client);

  Future<List<SuggestedProfile>> profiles() async {
    try {
      final rows = await _client.rpc('suggest_profiles', params: {'p_limit': 10});
      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
        return SuggestedProfile.fromJson(json);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<SuggestedGroup>> groups() async {
    try {
      final rows = await _client.rpc('suggest_groups', params: {'p_limit': 10});
      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'group-media', json['avatar_url'] as String?);
        return SuggestedGroup.fromJson(json);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}