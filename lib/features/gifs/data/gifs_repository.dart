import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/gifs/domain/gif_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GifsRepository {
  final SupabaseClient _client;
  const GifsRepository(this._client);

  Future<GifPage> load({required String locale, String? query, int offset = 0}) async {
    try {
      final result = await _client.functions.invoke('gifs', body: {'action': query == null || query.trim().isEmpty ? 'trending' : 'search', 'q': query?.trim(), 'locale': locale, 'limit': 24, 'offset': offset});
      if (result.status != 200) throw AppException(_errorKey(result.data));
      return GifPage.fromJson(Map<String, dynamic>.from(result.data as Map));
    } catch (error) {
      if (error is AppException) rethrow;
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> share(String onsent) async {
    try { await _client.functions.invoke('gifs', body: {'action': 'share', 'onsent': onsent}); } catch (_) {}
  }

  Future<String> sendMessage({required String conversationId, required GifResult gif, String? replyToId, String? clientId}) async {
    try { return (await _client.rpc('send_gif_message', params: {'p_conversation_id': conversationId, 'p_gif_url': gif.url, 'p_width': gif.width, 'p_height': gif.height, 'p_reply_to_id': replyToId, 'p_client_id': clientId})).toString(); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> createComment({required String postId, required GifResult gif, String? parentId, String? content}) async {
    try { return (await _client.rpc('create_gif_comment', params: {'p_post_id': postId, 'p_gif_url': gif.url, 'p_parent_id': parentId, 'p_content': content?.trim().isEmpty == true ? null : content?.trim()})).toString(); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  String _errorKey(Object? data) {
    final message = data is Map ? data['message']?.toString() : data?.toString();
    return message == 'gifs_not_configured' ? 'gifs.errors.not_configured' : message == 'gifs_query_required' ? 'gifs.errors.query_required' : 'gifs.errors.load';
  }
}