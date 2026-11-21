import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/polls/data/poll_repository.dart';
import 'package:hb_social/features/polls/domain/poll.dart';

final pollRepositoryProvider = Provider<PollRepository>((ref) => PollRepository(ref.watch(supabaseClientProvider)));
final pollForPostProvider = FutureProvider.autoDispose.family<Poll?, String>((ref, postId) => ref.watch(pollRepositoryProvider).fetchForPost(postId));

final pollsForPostsProvider = FutureProvider.autoDispose.family<Map<String, Poll>, String>((ref, postIdsKey) {
  final ids = postIdsKey.isEmpty ? <String>[] : postIdsKey.split(',');
  return ref.watch(pollRepositoryProvider).fetchForPosts(ids);
});