import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/safety/domain/country_safety_policy.dart';
import 'package:hb_social/features/safety/domain/user_strike.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafetyRepository {
  final SupabaseClient _client;

  const SafetyRepository(this._client);

  Future<void> hidePost(String postId) => _rpc('hide_post', {'p_post_id': postId});
  Future<void> unhidePost(String postId) => _rpc('unhide_post', {'p_post_id': postId});
  Future<void> muteUser(String userId) => _rpc('mute_user', {'p_user': userId});
  Future<void> unmuteUser(String userId) => _rpc('unmute_user', {'p_user': userId});
  Future<void> blockUser(String userId) => _rpc('block_user', {'p_user': userId});

  Future<CountrySafetyPolicy> countryPolicy(String countryCode) async {
    try {
      final row = await _client.from('country_policies').select('policy_type,policy_data').eq('country_code', countryCode).eq('policy_type', 'sensitive_content').maybeSingle();
      return CountrySafetyPolicy.fromJson(row?['policy_data']);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<UserStrike>> myStrikes() async {
    try {
      final rows = await _client.rpc('my_strikes');
      return (rows as List).map((row) => UserStrike.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String> report({required String targetType, required String targetId, required String reason, String? details}) async {
    try {
      final result = await _client.rpc('report_content', params: {'p_target_type': targetType, 'p_target_id': targetId, 'p_reason': reason, 'p_details': details?.trim().isEmpty == true ? null : details?.trim()});
      return result as String;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> _rpc(String function, Map<String, dynamic> params) async {
    try {
      await _client.rpc(function, params: params);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}