import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/chat/data/chat_realtime_service.dart';
import 'package:hb_social/features/chat/data/chat_repository.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/gifs/domain/gif_result.dart';

enum ConversationFilter { all, unread, groups }

class ConversationsState {
  final List<Conversation> items;
  final bool hasMore;
  final bool loadingMore;
  const ConversationsState({this.items = const [], this.hasMore = false, this.loadingMore = false});
  ConversationsState copyWith({List<Conversation>? items, bool? hasMore, bool? loadingMore}) => ConversationsState(items: items ?? this.items, hasMore: hasMore ?? this.hasMore, loadingMore: loadingMore ?? this.loadingMore);
}

class MessagesState {
  final List<ChatMessage> items;
  final bool hasOlder;
  final bool loadingOlder;
  const MessagesState({this.items = const [], this.hasOlder = false, this.loadingOlder = false});
  MessagesState copyWith({List<ChatMessage>? items, bool? hasOlder, bool? loadingOlder}) => MessagesState(items: items ?? this.items, hasOlder: hasOlder ?? this.hasOlder, loadingOlder: loadingOlder ?? this.loadingOlder);
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(ref.watch(supabaseClientProvider)));
final conversationsProvider = AsyncNotifierProvider<ConversationsNotifier, ConversationsState>(ConversationsNotifier.new);

class ConversationsNotifier extends AsyncNotifier<ConversationsState> {
  static const pageSize = 30;

  @override
  Future<ConversationsState> build() async {
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) return const ConversationsState();
    final items = await ref.watch(chatRepositoryProvider).listConversations(limit: pageSize);
    return ConversationsState(items: items, hasMore: items.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref.read(chatRepositoryProvider).listConversations(limit: pageSize, offset: current.items.length);
      state = AsyncData(ConversationsState(items: [...current.items, ...next], hasMore: next.length == pageSize));
    } catch (error, stackTrace) { state = AsyncError(error, stackTrace); }
  }
}

final conversationProvider = FutureProvider.autoDispose.family<Conversation?, String>((ref, id) async {
  final cached = ref.watch(conversationsProvider).value?.items.where((item) => item.id == id).firstOrNull;
  return cached ?? ref.watch(chatRepositoryProvider).conversation(id);
});

final recentConversationsProvider = FutureProvider<List<Conversation>>((ref) async => (await ref.watch(conversationsProvider.future)).items.take(3).toList());

final chatRealtimeProvider = Provider.autoDispose.family<ChatRealtimeService, String>((ref, conversationId) {
  final service = ChatRealtimeService(ref.watch(supabaseClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

final messagesProvider = AsyncNotifierProvider.autoDispose.family<MessagesNotifier, MessagesState, String>((conversationId) => MessagesNotifier(conversationId));

class MessagesNotifier extends AsyncNotifier<MessagesState> {
  final String conversationId;
  StreamSubscription<ChatRealtimeEvent>? _subscription;
  Timer? _markReadTimer;

  MessagesNotifier(this.conversationId);

  @override
  Future<MessagesState> build() async {
    final repository = ref.watch(chatRepositoryProvider);
    final newest = await repository.fetchMessages(conversationId);
    final service = ref.watch(chatRealtimeProvider(conversationId));
    await service.open(conversationId);
    _subscription = service.events.listen(_onRealtime);
    ref.onDispose(() { _subscription?.cancel(); _markReadTimer?.cancel(); });
    markRead();
    return MessagesState(items: newest.reversed.toList(), hasOlder: newest.length == ChatRepository.messagePageSize);
  }

  Future<void> _onRealtime(ChatRealtimeEvent event) async {
    if (event.kind == ChatRealtimeKind.messageInserted || event.kind == ChatRealtimeKind.messageUpdated) {
      final id = event.record['id']?.toString();
      if (id == null) return;
      try {
        final message = await ref.read(chatRepositoryProvider).fetchMessage(id);
        replace(message);
        final me = ref.read(authSessionProvider).value?.user.id;
        if (message.senderId != me) ref.invalidate(unreadConversationsCountProvider);
        ref.invalidate(conversationsProvider);
        ref.invalidate(unreadConversationsCountProvider);
      } catch (_) {}
    } else if (event.kind == ChatRealtimeKind.receiptsUpdated) {
      ref.invalidate(conversationsProvider);
      ref.invalidate(conversationProvider(conversationId));
    } else if (event.kind == ChatRealtimeKind.reconnected) {
      await refreshNewest();
    }
  }

  Future<void> refreshNewest() async {
    try {
      final newest = await ref.read(chatRepositoryProvider).fetchMessages(conversationId);
      final current = state.value;
      if (current == null) return;
      final byId = {for (final item in current.items) item.id: item};
      for (final item in newest) { byId[item.id] = item; }
      final items = byId.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncData(current.copyWith(items: items));
    } catch (_) {}
  }

  Future<void> loadOlder() async {
    final current = state.value;
    if (current == null || !current.hasOlder || current.loadingOlder || current.items.isEmpty) return;
    state = AsyncData(current.copyWith(loadingOlder: true));
    try {
      final oldest = current.items.first;
      final older = await ref.read(chatRepositoryProvider).fetchMessages(conversationId, before: oldest.createdAt, beforeId: oldest.id);
      state = AsyncData(MessagesState(items: [...older.reversed, ...current.items], hasOlder: older.length == ChatRepository.messagePageSize));
    } catch (error, stackTrace) { state = AsyncError(error, stackTrace); }
  }

  Future<void> send(String body, {String? replyToId, required String clientId}) async {
    final profile = ref.read(currentProfileProvider).value;
    final userId = ref.read(authSessionProvider).value?.user.id;
    if (profile == null || userId == null) return;
    final optimistic = ChatMessage(id: clientId, conversationId: conversationId, senderId: userId, kind: 'text', body: body.trim(), replyToId: replyToId, clientId: clientId, status: 'sent', createdAt: DateTime.now().toUtc(), sender: profile, localState: LocalMessageState.sending);
    append(optimistic);
    try {
      final id = await ref.read(chatRepositoryProvider).sendText(conversationId, body, replyToId: replyToId, clientId: clientId);
      final current = state.value;
      if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(id: id, localState: LocalMessageState.sent) else item]));
      ref.invalidate(conversationsProvider);
    } catch (_) {
      final current = state.value;
      if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(localState: LocalMessageState.failed) else item]));
      rethrow;
    }
  }

  Future<void> sendGif(GifResult gif, {String? replyToId, required String clientId}) async {
    final profile = ref.read(currentProfileProvider).value;
    final userId = ref.read(authSessionProvider).value?.user.id;
    if (profile == null || userId == null) return;
    final optimistic = ChatMessage(id: clientId, conversationId: conversationId, senderId: userId, kind: 'gif', body: 'GIF', mediaPath: gif.url, replyToId: replyToId, clientId: clientId, mediaWidth: gif.width, mediaHeight: gif.height, status: 'sent', createdAt: DateTime.now().toUtc(), sender: profile, localState: LocalMessageState.sending);
    append(optimistic);
    try {
      final id = await ref.read(chatRepositoryProvider).sendGif(conversationId, url: gif.url, width: gif.width, height: gif.height, replyToId: replyToId, clientId: clientId);
      final current = state.value;
      if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(id: id, localState: LocalMessageState.sent) else item]));
      ref.invalidate(conversationsProvider);
    } catch (_) {
      final current = state.value;
      if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(localState: LocalMessageState.failed) else item]));
      rethrow;
    }
  }

  Future<void> retry(ChatMessage message) async {
    if (message.localMedia != null) { await sendMedia(message.localMedia!, kind: message.kind, body: message.body, clientId: message.clientId!); return; }
    remove(message.id); await send(message.body, replyToId: message.replyToId, clientId: message.clientId!);
  }

  Future<void> sendMedia(PreparedChatMedia media, {required String kind, String body = '', required String clientId}) async {
    final profile = ref.read(currentProfileProvider).value;
    final userId = ref.read(authSessionProvider).value?.user.id;
    if (profile == null || userId == null) return;
    final optimistic = ChatMessage(id: clientId, conversationId: conversationId, senderId: userId, kind: kind, body: body.trim(), durationMs: media.durationMs, clientId: clientId, mediaWidth: media.width, mediaHeight: media.height, mediaMime: media.mime, mediaSize: media.bytes.length, status: 'sent', createdAt: DateTime.now().toUtc(), sender: profile, localState: LocalMessageState.sending, localBytes: media.bytes, localMedia: media, meta: {'waveform': media.waveform});
    remove(clientId); append(optimistic);
    final path = '$conversationId/$userId/$clientId.${media.extension}';
    try {
      await ref.read(mediaUploadServiceProvider).uploadBytes(bucket: 'chat-media', path: path, bytes: media.bytes, contentType: media.mime, onProgress: (value) {
        final current = state.value;
        if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(uploadProgress: value) else item]));
      });
      final id = await ref.read(chatRepositoryProvider).sendMedia(conversationId, kind: kind, mediaPath: path, clientId: clientId, body: body, width: media.width, height: media.height, durationMs: media.durationMs, mime: media.mime, size: media.bytes.length);
      final current = state.value;
      if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(id: id, mediaPath: path, localState: LocalMessageState.sent, uploadProgress: 1) else item]));
      ref.invalidate(conversationsProvider);
    } catch (_) {
      final current = state.value;
      if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) if (item.clientId == clientId) item.copyWith(localState: LocalMessageState.failed) else item]));
      rethrow;
    }
  }

  Future<void> edit(ChatMessage message, String body) async {
    await ref.read(chatRepositoryProvider).editMessage(message.id, body);
    replace(message.copyWith(body: body.trim(), status: 'edited'));
  }

  Future<void> delete(ChatMessage message) async {
    if (message.localState == LocalMessageState.failed) { remove(message.id); return; }
    await ref.read(chatRepositoryProvider).deleteMessage(message.id);
    if (message.mediaPath != null && message.kind != 'gif') { try { await ref.read(mediaUploadServiceProvider).delete('chat-media', message.mediaPath); } catch (_) {} }
    replace(message.copyWith(body: '', status: 'deleted'));
  }

  void append(ChatMessage message) {
    final current = state.value;
    if (current == null) return;
    if (current.items.any((item) => item.id == message.id || (message.clientId != null && item.clientId == message.clientId))) { replace(message); return; }
    state = AsyncData(current.copyWith(items: [...current.items, message]));
  }

  void replace(ChatMessage message) {
    final current = state.value;
    if (current == null) return;
    final matches = current.items.any((item) => item.id == message.id || (message.clientId != null && item.clientId == message.clientId));
    final items = matches ? [for (final item in current.items) if (item.id == message.id || (message.clientId != null && item.clientId == message.clientId)) message else item] : [...current.items, message];
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = AsyncData(current.copyWith(items: items));
  }

  void remove(String id) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.where((item) => item.id != id).toList()));
  }

  void markRead() {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await ref.read(chatRepositoryProvider).markRead(conversationId);
        ref.invalidate(unreadConversationsCountProvider);
        ref.invalidate(conversationsProvider);
      } catch (_) {}
    });
  }
}

final typingProvider = NotifierProvider.autoDispose.family<TypingNotifier, Map<String, String>, String>((conversationId) => TypingNotifier(conversationId));

class TypingNotifier extends Notifier<Map<String, String>> {
  final String conversationId;
  StreamSubscription<ChatRealtimeEvent>? _subscription;
  final Map<String, Timer> _timers = {};

  TypingNotifier(this.conversationId);

  @override
  Map<String, String> build() {
    final service = ref.watch(chatRealtimeProvider(conversationId));
    _subscription = service.events.listen((event) {
      if (event.kind != ChatRealtimeKind.typing && event.kind != ChatRealtimeKind.typingStopped) return;
      final id = event.record['user_id']?.toString();
      if (id == null || id == ref.read(authSessionProvider).value?.user.id) return;
      _timers.remove(id)?.cancel();
      if (event.kind == ChatRealtimeKind.typingStopped) { state = {...state}..remove(id); return; }
      state = {...state, id: event.record['display_name']?.toString() ?? ''};
      _timers[id] = Timer(const Duration(seconds: 4), () => state = {...state}..remove(id));
    });
    ref.onDispose(() { _subscription?.cancel(); for (final timer in _timers.values) { timer.cancel(); } });
    return const {};
  }
}

final unreadConversationsCountProvider = AsyncNotifierProvider<UnreadConversationsCountNotifier, int>(UnreadConversationsCountNotifier.new);

class UnreadConversationsCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    if (await ref.watch(authSessionProvider.future) == null) return 0;
    try { return await ref.watch(chatRepositoryProvider).unreadCount(); } catch (_) { return 0; }
  }
}

final peopleSearchProvider = FutureProvider.autoDispose.family<List<UserProfile>, String>((ref, query) => ref.watch(chatRepositoryProvider).searchPeople(query));

class ChatDockState {
  final bool listOpen;
  final List<String> openIds;
  final Set<String> minimizedIds;
  const ChatDockState({this.listOpen = false, this.openIds = const [], this.minimizedIds = const {}});
  ChatDockState copyWith({bool? listOpen, List<String>? openIds, Set<String>? minimizedIds}) => ChatDockState(listOpen: listOpen ?? this.listOpen, openIds: openIds ?? this.openIds, minimizedIds: minimizedIds ?? this.minimizedIds);
}

class ChatDockNotifier extends Notifier<ChatDockState> {
  @override
  ChatDockState build() => const ChatDockState();
  void toggleList() => state = state.copyWith(listOpen: !state.listOpen);
  void open(String id) {
    final ids = [...state.openIds.where((item) => item != id), id];
    state = state.copyWith(listOpen: false, openIds: ids.length > 3 ? ids.sublist(ids.length - 3) : ids, minimizedIds: {...state.minimizedIds}..remove(id));
  }
  void close(String id) => state = state.copyWith(openIds: state.openIds.where((item) => item != id).toList(), minimizedIds: {...state.minimizedIds}..remove(id));
  void toggleMinimized(String id) {
    final minimized = {...state.minimizedIds};
    minimized.contains(id) ? minimized.remove(id) : minimized.add(id);
    state = state.copyWith(minimizedIds: minimized);
  }
}

final chatDockProvider = NotifierProvider<ChatDockNotifier, ChatDockState>(ChatDockNotifier.new);