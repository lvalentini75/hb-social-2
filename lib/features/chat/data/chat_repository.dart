import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  static const messagePageSize = 30;
  static const _senderSelect = 'id,username,display_name,avatar_url,verification_level';
  final SupabaseClient _client;
  final Map<String, String> _signedUrls = {};

  ChatRepository(this._client);

  Future<List<Conversation>> listConversations({int limit = 30, int offset = 0}) async {
    try {
      final rows = await _client.rpc('list_conversations', params: {'p_limit': limit, 'p_offset': offset});
      return (rows as List).map((raw) => _conversation(Map<String, dynamic>.from(raw as Map))).toList();
    } catch (error) { throw _mapError(error); }
  }

  Future<Conversation?> conversation(String id) async => (await listConversations(limit: 100)).where((item) => item.id == id).firstOrNull;
  Future<String> startDirect(String userId) => _uuidRpc('start_direct_conversation', {'p_user': userId});
  Future<String> createGroup(String? title, List<String> userIds) => _uuidRpc('create_group_conversation', {'p_title': title?.trim().isEmpty == true ? null : title?.trim(), 'p_user_ids': userIds});
  Future<String> sendText(String conversationId, String body, {String? replyToId, required String clientId}) => _uuidRpc('send_message', {'p_conversation_id': conversationId, 'p_kind': 'text', 'p_body': body.trim(), 'p_reply_to_id': replyToId, 'p_client_id': clientId});
  Future<String> sendGif(String conversationId, {required String url, required int width, required int height, String? replyToId, required String clientId}) => _uuidRpc('send_gif_message', {'p_conversation_id': conversationId, 'p_gif_url': url, 'p_width': width, 'p_height': height, 'p_reply_to_id': replyToId, 'p_client_id': clientId});
  Future<void> editMessage(String messageId, String body) => _voidRpc('edit_message', {'p_message_id': messageId, 'p_body': body.trim()});
  Future<void> deleteMessage(String messageId) => _voidRpc('delete_message', {'p_message_id': messageId});
  Future<void> markRead(String conversationId) => _voidRpc('mark_conversation_read', {'p_conversation_id': conversationId});
  Future<String> sendMedia(String conversationId, {required String kind, required String mediaPath, required String clientId, String? body, int? width, int? height, int? durationMs, required String mime, required int size}) => _uuidRpc('send_message', {'p_conversation_id': conversationId, 'p_kind': kind, 'p_body': body?.trim().isEmpty == true ? null : body?.trim(), 'p_media_path': mediaPath, 'p_media_width': width, 'p_media_height': height, 'p_duration_ms': durationMs, 'p_media_mime': mime, 'p_media_size': size, 'p_client_id': clientId});
  Future<void> addParticipants(String id, List<String> users) => _voidRpc('add_conversation_participants', {'p_conversation_id': id, 'p_user_ids': users});
  Future<void> removeParticipant(String id, String user) => _voidRpc('remove_conversation_participant', {'p_conversation_id': id, 'p_user': user});
  Future<void> leaveConversation(String id) => _voidRpc('leave_conversation', {'p_conversation_id': id});
  Future<void> renameConversation(String id, String title) => _voidRpc('rename_conversation', {'p_conversation_id': id, 'p_title': title.trim()});
  Future<void> setMuted(String id, DateTime? until) => _voidRpc('set_conversation_muted', {'p_conversation_id': id, 'p_until': until?.toUtc().toIso8601String()});

  Future<String> signedMediaUrl(String path, {bool refresh = false}) async {
    if (!refresh && _signedUrls[path] != null) return _signedUrls[path]!;
    try {
      final url = await _client.storage.from('chat-media').createSignedUrl(path, 3600);
      _signedUrls[path] = url;
      return url;
    } catch (error) { throw _mapError(error); }
  }

  Future<List<ChatMessage>> sharedImages(String conversationId) async {
    try {
      final rows = await _client.from('messages').select('*,sender:user_profiles!sender_id($_senderSelect)').eq('conversation_id', conversationId).eq('kind', 'image').neq('status', 'deleted').order('created_at', ascending: false);
      return (rows as List).map((raw) => _message(Map<String, dynamic>.from(raw as Map))).toList();
    } catch (error) { throw _mapError(error); }
  }

  Future<int> unreadCount() async {
    try { return ((await _client.rpc('unread_conversations_count')) as num?)?.toInt() ?? 0; }
    catch (error) { throw _mapError(error); }
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId, {DateTime? before, String? beforeId}) async {
    try {
      var query = _client.from('messages').select('*,sender:user_profiles!sender_id($_senderSelect)').eq('conversation_id', conversationId);
      if (before != null && beforeId != null) query = query.or('created_at.lt.${before.toIso8601String()},and(created_at.eq.${before.toIso8601String()},id.lt.$beforeId)');
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(messagePageSize);
      return (rows as List).map((raw) => _message(Map<String, dynamic>.from(raw as Map))).toList();
    } catch (error) { throw _mapError(error); }
  }

  Future<ChatMessage> fetchMessage(String id) async {
    try {
      final row = await _client.from('messages').select('*,sender:user_profiles!sender_id($_senderSelect)').eq('id', id).single();
      return _message(Map<String, dynamic>.from(row));
    } catch (error) { throw _mapError(error); }
  }

  Future<List<UserProfile>> searchPeople(String query) async {
    final me = _client.auth.currentUser?.id;
    if (me == null || query.trim().isEmpty) return const [];
    try {
      final escaped = query.trim().replaceAll('%', r'\%').replaceAll('_', r'\_');
      final rows = await _client.from('user_profiles').select(_senderSelect).eq('status', 'active').neq('id', me).or('display_name.ilike.%$escaped%,username.ilike.%$escaped%').limit(20);
      return (rows as List).map((raw) => _profile(Map<String, dynamic>.from(raw as Map))).toList();
    } catch (error) { throw _mapError(error); }
  }

  Future<String> _uuidRpc(String function, Map<String, dynamic> params) async {
    try { return (await _client.rpc(function, params: params)).toString(); }
    catch (error) { throw _mapError(error); }
  }

  Future<void> _voidRpc(String function, Map<String, dynamic> params) async {
    try { await _client.rpc(function, params: params); }
    catch (error) { throw _mapError(error); }
  }

  Conversation _conversation(Map<String, dynamic> json) {
    final participants = json['participants'];
    if (participants is List) {
      json['participants'] = participants.map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        item['avatar_url'] = storagePublicUrl(_client, 'avatars', item['avatar_url'] as String?);
        return item;
      }).toList();
    }
    return Conversation.fromJson(json);
  }

  ChatMessage _message(Map<String, dynamic> json) {
    final sender = Map<String, dynamic>.from(json['sender'] as Map? ?? const {});
    sender['avatar_url'] = storagePublicUrl(_client, 'avatars', sender['avatar_url'] as String?);
    json['sender'] = sender;
    return ChatMessage.fromJson(json);
  }

  UserProfile _profile(Map<String, dynamic> json) {
    json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
    return UserProfile.fromJson(json);
  }

  AppException _mapError(Object error) {
    final message = error is PostgrestException ? error.message.toLowerCase() : error.toString().toLowerCase();
    const errors = {
      'message_not_allowed': 'chat.errors.message_not_allowed', 'message_blocked': 'chat.errors.message_blocked', 'content_blocked': 'chat.errors.content_blocked',
      'conversation_too_many': 'chat.errors.conversation_too_many', 'conversation_permission_denied': 'chat.errors.permission_denied', 'conversation_not_found': 'chat.errors.not_found',
      'conversation_self': 'chat.errors.self', 'conversation_title_invalid': 'chat.errors.title_invalid', 'conversation_not_group': 'chat.errors.not_group',
      'message_kind_invalid': 'chat.errors.kind_invalid', 'message_body_required': 'chat.errors.body_required', 'message_body_too_long': 'chat.errors.body_too_long',
      'message_reply_invalid': 'chat.errors.reply_invalid', 'message_not_found': 'chat.errors.message_not_found', 'user_not_found': 'chat.errors.user_not_found',
      'message_media_required': 'chat_b.errors.media_required', 'message_media_path_invalid': 'chat_b.errors.media_path_invalid', 'message_duration_invalid': 'chat_b.errors.duration_invalid',
      'not_authenticated': 'errors.login_required', 'account_suspended': 'suspended.write_blocked',
    };
    for (final entry in errors.entries) { if (message.contains(entry.key)) return AppException(entry.value); }
    return ErrorMapper.fromSupabase(error);
  }
}