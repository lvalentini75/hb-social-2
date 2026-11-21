import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RealtimeConnectionStatus { connected, reconnecting }

class PostRealtimeEvent {
  final String id;
  final String status;
  final int reactionCount;
  final int commentCount;
  final int shareCount;

  const PostRealtimeEvent({required this.id, required this.status, required this.reactionCount, required this.commentCount, required this.shareCount});

  factory PostRealtimeEvent.fromJson(Map<String, dynamic> json) => PostRealtimeEvent(
    id: json['id'] as String,
    status: json['status'] as String? ?? 'published',
    reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
    commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
  );
}

class CommentRealtimeEvent {
  final String id;
  final String postId;
  final bool deleted;

  const CommentRealtimeEvent({required this.id, required this.postId, required this.deleted});
}

class ForumRealtimeEvent {
  final String table;
  final PostgresChangeEvent event;
  final Map<String, dynamic> record;
  const ForumRealtimeEvent({required this.table, required this.event, required this.record});
}

/// Owns every Supabase Realtime channel used by the social application.
class RealtimeService with WidgetsBindingObserver {
  final SupabaseClient _client;
  final _postEvents = StreamController<PostRealtimeEvent>.broadcast();
  final _notificationEvents = StreamController<String>.broadcast();
  final _storyEvents = StreamController<void>.broadcast();
  final _onlineUsers = StreamController<Set<String>>.broadcast();
  final _connectionStatus = StreamController<RealtimeConnectionStatus>.broadcast();
  final Map<String, RealtimeChannel> _globalChannels = {};
  final Map<String, RealtimeChannel> _commentChannels = {};
  final Map<String, StreamController<CommentRealtimeEvent>> _commentEvents = {};
  final Map<String, int> _commentListeners = {};
  final Map<String, RealtimeChannel> _forumChannels = {};
  final Map<String, StreamController<ForumRealtimeEvent>> _forumEvents = {};
  final Map<String, bool> _subscriptions = {};
  Timer? _presenceTimer;
  String? _userId;
  String? _username;
  bool _foreground = true;

  RealtimeService(this._client);

  Stream<PostRealtimeEvent> get postEvents => _postEvents.stream;
  Stream<String> get notificationEvents => _notificationEvents.stream;
  Stream<void> get storyEvents => _storyEvents.stream;
  Stream<Set<String>> get onlineUsers => _onlineUsers.stream;
  Stream<RealtimeConnectionStatus> get connectionStatus => _connectionStatus.stream;

  Future<void> configure({required String countryCode, String? userId, String? username}) async {
    await _removeGlobalChannels();
    _userId = userId;
    _username = username;
    _subscriptions.clear();
    _connectionStatus.add(RealtimeConnectionStatus.reconnecting);
    _openPosts(countryCode);
    _openStories(countryCode);
    if (userId != null) {
      _openNotifications(userId);
      _openPresence(userId, username ?? '');
      WidgetsBinding.instance.addObserver(this);
      await _touchPresence();
      _presenceTimer = Timer.periodic(const Duration(minutes: 2), (_) => _touchPresence());
    } else {
      _onlineUsers.add(const {});
    }
  }

  Stream<CommentRealtimeEvent> openComments(String postId) {
    _commentListeners[postId] = (_commentListeners[postId] ?? 0) + 1;
    final controller = _commentEvents.putIfAbsent(postId, () => StreamController<CommentRealtimeEvent>.broadcast());
    if (!_commentChannels.containsKey(postId)) {
      final channel = _client.channel('comments:$postId');
      channel
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'comments', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: postId), callback: (payload) {
          final row = payload.newRecord;
          controller.add(CommentRealtimeEvent(id: row['id'] as String, postId: postId, deleted: false));
        })
        .onPostgresChanges(event: PostgresChangeEvent.delete, schema: 'public', table: 'comments', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: postId), callback: (payload) {
          final row = payload.oldRecord;
          controller.add(CommentRealtimeEvent(id: row['id'] as String, postId: postId, deleted: true));
        });
      _commentChannels[postId] = channel;
      channel.subscribe((status, error) => _logStatus('comments:$postId', status, error));
    }
    return controller.stream;
  }

  Future<void> closeComments(String postId) async {
    final remaining = (_commentListeners[postId] ?? 1) - 1;
    if (remaining > 0) {
      _commentListeners[postId] = remaining;
      return;
    }
    _commentListeners.remove(postId);
    final channel = _commentChannels.remove(postId);
    if (channel != null) await _client.removeChannel(channel);
    await _commentEvents.remove(postId)?.close();
  }

  Stream<ForumRealtimeEvent> openForumThread(String threadId) {
    final controller = _forumEvents.putIfAbsent(threadId, () => StreamController<ForumRealtimeEvent>.broadcast());
    if (_forumChannels.containsKey(threadId)) return controller.stream;
    final channel = _client.channel('forum_thread:$threadId');
    void reply(PostgresChangePayload payload) => controller.add(ForumRealtimeEvent(table: 'forum_replies', event: payload.eventType, record: payload.eventType == PostgresChangeEvent.delete ? payload.oldRecord : payload.newRecord));
    channel
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'forum_replies', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'thread_id', value: threadId), callback: reply)
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'forum_replies', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'thread_id', value: threadId), callback: reply)
      .onPostgresChanges(event: PostgresChangeEvent.delete, schema: 'public', table: 'forum_replies', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'thread_id', value: threadId), callback: reply)
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'forum_threads', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: threadId), callback: (payload) => controller.add(ForumRealtimeEvent(table: 'forum_threads', event: payload.eventType, record: payload.newRecord)));
    _forumChannels[threadId] = channel;
    channel.subscribe((status, error) => _logStatus('forum_thread:$threadId', status, error));
    return controller.stream;
  }

  Future<void> closeForumThread(String threadId) async {
    final channel = _forumChannels.remove(threadId);
    if (channel != null) await _client.removeChannel(channel);
    await _forumEvents.remove(threadId)?.close();
  }

  void _openPosts(String countryCode) {
    final channel = _client.channel('posts:$countryCode');
    channel.onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'posts', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'country_code', value: countryCode), callback: (payload) => _postEvents.add(PostRealtimeEvent.fromJson(payload.newRecord)));
    _subscribe('posts', channel);
  }

  void _openStories(String countryCode) {
    final channel = _client.channel('stories:$countryCode');
    void changed(PostgresChangePayload _) => _storyEvents.add(null);
    channel
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'stories', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'country_code', value: countryCode), callback: changed)
      .onPostgresChanges(event: PostgresChangeEvent.delete, schema: 'public', table: 'stories', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'country_code', value: countryCode), callback: changed);
    _subscribe('stories', channel);
  }

  void _openNotifications(String userId) {
    final channel = _client.channel('notifications:$userId');
    void changed(PostgresChangePayload payload) => _notificationEvents.add(payload.newRecord['id'] as String);
    final filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId);
    channel
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'notifications', filter: filter, callback: changed)
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'notifications', filter: filter, callback: changed);
    _subscribe('notifications', channel);
  }

  void _openPresence(String userId, String username) {
    final channel = _client.channel('presence:online', opts: const RealtimeChannelConfig(self: true));
    channel.onPresenceSync((_) => _publishPresence(channel));
    _globalChannels['presence'] = channel;
    _subscriptions['presence'] = false;
    channel.subscribe((status, error) async {
      _handleStatus('presence', status, error);
      if (status == RealtimeSubscribeStatus.subscribed) await channel.track({'user_id': userId, 'username': username, 'at': DateTime.now().toUtc().toIso8601String()});
    });
  }

  void _publishPresence(RealtimeChannel channel) {
    final ids = <String>{};
    for (final state in channel.presenceState()) {
      for (final presence in state.presences) {
        final id = presence.payload['user_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    _onlineUsers.add(ids);
  }

  void _subscribe(String purpose, RealtimeChannel channel) {
    _globalChannels[purpose] = channel;
    _subscriptions[purpose] = false;
    channel.subscribe((status, error) => _handleStatus(purpose, status, error));
  }

  void _handleStatus(String purpose, RealtimeSubscribeStatus status, Object? error) {
    _subscriptions[purpose] = status == RealtimeSubscribeStatus.subscribed;
    _connectionStatus.add(_subscriptions.values.every((connected) => connected) ? RealtimeConnectionStatus.connected : RealtimeConnectionStatus.reconnecting);
    _logStatus(purpose, status, error);
  }

  void _logStatus(String purpose, RealtimeSubscribeStatus status, Object? error) => developer.log('Realtime $purpose: $status', name: 'hb.realtime', error: error);

  Future<void> _touchPresence() async {
    if (!_foreground || _userId == null) return;
    try { await _client.rpc('touch_presence'); } catch (error) { developer.log('Presence heartbeat failed', name: 'hb.realtime', error: error); }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _touchPresence();
  }

  Future<void> _removeGlobalChannels() async {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    _presenceTimer = null;
    final presence = _globalChannels['presence'];
    if (presence != null) {
      try { await presence.untrack(); } catch (_) {}
    }
    for (final channel in _globalChannels.values) {
      await _client.removeChannel(channel);
    }
    _globalChannels.clear();
  }

  Future<void> dispose() async {
    await _removeGlobalChannels();
    for (final postId in _commentChannels.keys.toList()) { await closeComments(postId); }
    for (final threadId in _forumChannels.keys.toList()) { await closeForumThread(threadId); }
    await _postEvents.close();
    await _notificationEvents.close();
    await _storyEvents.close();
    await _onlineUsers.close();
    await _connectionStatus.close();
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref.watch(supabaseClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

final onlineUsersProvider = StreamProvider<Set<String>>((ref) => ref.watch(realtimeServiceProvider).onlineUsers);