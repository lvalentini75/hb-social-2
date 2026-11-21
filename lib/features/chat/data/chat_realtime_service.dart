import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum ChatRealtimeKind { messageInserted, messageUpdated, receiptsUpdated, typing, typingStopped, reconnected }

class ChatRealtimeEvent {
  final ChatRealtimeKind kind;
  final Map<String, dynamic> record;
  const ChatRealtimeEvent(this.kind, [this.record = const {}]);
}

/// Owns the single Realtime channel for the currently open conversation.
class ChatRealtimeService {
  final SupabaseClient _client;
  final _events = StreamController<ChatRealtimeEvent>.broadcast();
  RealtimeChannel? _channel;
  String? _conversationId;

  ChatRealtimeService(this._client);

  Stream<ChatRealtimeEvent> get events => _events.stream;

  Future<void> open(String conversationId) async {
    if (_conversationId == conversationId && _channel != null) return;
    await close();
    _conversationId = conversationId;
    final channel = _client.channel('conv:$conversationId');
    final filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId);
    channel
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages', filter: filter, callback: (payload) => _events.add(ChatRealtimeEvent(ChatRealtimeKind.messageInserted, payload.newRecord)))
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'messages', filter: filter, callback: (payload) => _events.add(ChatRealtimeEvent(ChatRealtimeKind.messageUpdated, payload.newRecord)))
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'conversation_participants', filter: filter, callback: (payload) => _events.add(ChatRealtimeEvent(ChatRealtimeKind.receiptsUpdated, payload.newRecord)))
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'conversations', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: conversationId), callback: (_) => _events.add(const ChatRealtimeEvent(ChatRealtimeKind.reconnected)))
      .onBroadcast(event: 'typing', callback: (payload) => _events.add(ChatRealtimeEvent(ChatRealtimeKind.typing, Map<String, dynamic>.from(payload))))
      .onBroadcast(event: 'typing_stop', callback: (payload) => _events.add(ChatRealtimeEvent(ChatRealtimeKind.typingStopped, Map<String, dynamic>.from(payload))));
    _channel = channel;
    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) _events.add(const ChatRealtimeEvent(ChatRealtimeKind.reconnected));
    });
  }

  Future<void> sendTyping({required String userId, required String displayName, required bool stopped}) async {
    await _channel?.sendBroadcastMessage(event: stopped ? 'typing_stop' : 'typing', payload: {'user_id': userId, 'display_name': displayName});
  }

  Future<void> close() async {
    final channel = _channel;
    _channel = null;
    _conversationId = null;
    if (channel != null) await _client.removeChannel(channel);
  }

  Future<void> dispose() async {
    await close();
    await _events.close();
  }
}