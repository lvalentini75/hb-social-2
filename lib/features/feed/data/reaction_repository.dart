import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/feed/domain/reaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionRepository {
  static const pageSize = 20;
  final SupabaseClient _client;

  const ReactionRepository(this._client);

  Future<ReactionToggleResult> toggle(String postId, ReactionType type) async {
    if (_client.auth.currentUser == null) throw const AppException('errors.login_required');
    try {
      final result = await _client.rpc('toggle_reaction', params: {'p_post_id': postId, 'p_reaction_type': type.value});
      final row = result is List ? result.first as Map : result as Map;
      return ReactionToggleResult(myReaction: row['my_reaction'] as String?, reactionCount: (row['reaction_count'] as num).toInt());
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('not_authenticated')) throw const AppException('errors.login_required');
      if (message.contains('reaction_invalid')) throw const AppException('errors.generic');
      throw ErrorMapper.fromSupabase(error);
    }
  }

  /// Single source of truth for per-post reaction data (summary, counts, myReaction).
  /// One RPC call per page; never a direct query on the `reactions` table.
  Future<Map<String, PostReactionsInfo>> summaryBatch(List<String> postIds) async {
    try {
      if (postIds.isEmpty) return {};
      final rows = await _client.rpc('reactions_summary', params: {'p_post_ids': postIds});
      final summaries = <String, List<ReactionSummary>>{};
      final mine = <String, String>{};
      for (final row in rows as List) {
        final json = Map<String, dynamic>.from(row as Map);
        final postId = json['post_id'] as String;
        final type = ReactionTypeUi.parse(json['reaction_type'] as String?);
        if (type == null) continue;
        summaries.putIfAbsent(postId, () => []).add(ReactionSummary(type: type, count: (json['reaction_count'] as num).toInt()));
        if (json['is_mine'] == true) mine[postId] = type.value;
      }
      return {for (final entry in summaries.entries) entry.key: PostReactionsInfo(summary: entry.value, myReaction: mine[entry.key])};
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Map<String, String>> namesBatch(List<String> postIds) async {
    try {
      if (postIds.isEmpty) return {};
      final rows = await _client.rpc('reactions_names', params: {'p_post_ids': postIds});
      return {
        for (final row in rows as List)
          if ((row as Map)['display_name'] != null) row['post_id'] as String: row['display_name'] as String,
      };
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Page<PostReaction>> fetch({required String postId, ReactionType? type, PageCursor? cursor}) async {
    try {
      // The ONLY direct query on `reactions` allowed in the client: paginated list for one post, no aggregates.
      var query = _client.from('reactions').select('id,reaction_type,created_at,user:user_profiles!reactions_user_id_fkey(id,username,display_name,avatar_url,verification_level)').eq('post_id', postId);
      if (type != null) query = query.eq('reaction_type', type.value);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = (rows as List).map((row) => PostReaction.fromJson(Map<String, dynamic>.from(row as Map))).toList();
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}