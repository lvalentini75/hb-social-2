import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/polls/domain/poll.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PollRepository {
  final SupabaseClient _client;

  const PollRepository(this._client);

  Future<Poll?> fetchForPost(String postId) async => (await fetchForPosts([postId]))[postId];

  Future<Map<String, Poll>> fetchForPosts(List<String> postIds) async {
    if (postIds.isEmpty) return const {};
    try {
      final rows = await _client.from('polls').select('*,options:poll_options(*)').inFilter('post_id', postIds);
      final rawRows = (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
      final voteIds = <String, List<String>>{};
      if (_client.auth.currentUser != null && rawRows.isNotEmpty) {
        final pollIds = rawRows.map((row) => row['id'] as String).toList();
        final votes = await _client.from('poll_votes').select('poll_id,option_id').inFilter('poll_id', pollIds).eq('user_id', _client.auth.currentUser!.id);
        for (final vote in votes as List) {
          voteIds.putIfAbsent(vote['poll_id'] as String, () => []).add(vote['option_id'] as String);
        }
      }
      final polls = <String, Poll>{};
      for (final json in rawRows) {
        json['my_option_ids'] = voteIds[json['id']] ?? const <String>[];
        final poll = Poll.fromJson(json);
        polls[poll.postId] = poll;
      }
      return polls;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Poll> vote(Poll poll, Set<String> optionIds) async {
    if (_client.auth.currentUser == null) throw const AppException('errors.login_required');
    try {
      final rows = await _client.rpc('vote_poll', params: {'p_poll_id': poll.id, 'p_option_ids': optionIds.toList()});
      final updates = <String, Map<String, dynamic>>{};
      var totalVotes = poll.totalVotes;
      final myVotes = <String>{};
      for (final raw in rows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        updates[row['option_id'] as String] = row;
        totalVotes = (row['total_votes'] as num?)?.toInt() ?? totalVotes;
        if (row['my_vote'] == true) myVotes.add(row['option_id'] as String);
      }
      return poll.copyWith(
        totalVotes: totalVotes,
        myOptionIds: myVotes,
        options: poll.options.map((option) => option.copyWith(voteCount: (updates[option.id]?['vote_count'] as num?)?.toInt())).toList(),
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('poll_closed')) throw const AppException('errors.poll_closed');
      if (message.contains('poll_single_choice')) throw const AppException('errors.poll_single_choice');
      if (message.contains('not_authenticated')) throw const AppException('errors.login_required');
      throw ErrorMapper.fromSupabase(error);
    }
  }
}