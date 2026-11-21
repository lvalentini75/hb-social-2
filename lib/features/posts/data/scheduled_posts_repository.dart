import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/home/data/feed_repository.dart';
import 'package:hb_social/features/posts/domain/scheduled_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduledPostsRepository {
  final SupabaseClient _client;
  final FeedRepository _feedRepository;

  ScheduledPostsRepository(this._client) : _feedRepository = FeedRepository(_client);

  Future<List<ScheduledPost>> list({String? pageId}) async {
    try {
      final rows = await _client.rpc('my_scheduled_posts', params: {'p_page_id': pageId}).select(FeedRepository.postSelect).order('scheduled_at');
      final parsed = await _feedRepository.parsePosts(rows as List);
      return [for (var index = 0; index < parsed.length; index++) ScheduledPost(post: parsed[index], scheduledAt: DateTime.parse((rows[index] as Map)['scheduled_at'].toString()).toUtc())];
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> reschedule(String id, DateTime scheduledAt) => _rpc('reschedule_post', {'p_post_id': id, 'p_scheduled_at': scheduledAt.toUtc().toIso8601String()});
  Future<void> publishNow(String id) => _rpc('publish_post_now', {'p_post_id': id});

  Future<void> delete(String id) async {
    try {
      await _client.from('posts').delete().eq('id', id);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try {
      await _client.rpc(name, params: params);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}