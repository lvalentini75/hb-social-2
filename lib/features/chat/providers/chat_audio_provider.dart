import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/chat/data/chat_repository.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:just_audio/just_audio.dart';

class ChatAudioState {
  final String? messageId;
  final bool playing;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? errorKey;
  const ChatAudioState({this.messageId, this.playing = false, this.position = Duration.zero, this.duration = Duration.zero, this.speed = 1, this.errorKey});
}

class ChatAudioNotifier extends Notifier<ChatAudioState> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _conversationId;

  @override
  ChatAudioState build() {
    _subscriptions.add(_player.positionStream.listen((value) => state = ChatAudioState(messageId: state.messageId, playing: state.playing, position: value, duration: state.duration, speed: state.speed, errorKey: state.errorKey)));
    _subscriptions.add(_player.durationStream.listen((value) => state = ChatAudioState(messageId: state.messageId, playing: state.playing, position: state.position, duration: value ?? state.duration, speed: state.speed, errorKey: state.errorKey)));
    _subscriptions.add(_player.playerStateStream.listen((value) {
      state = ChatAudioState(messageId: state.messageId, playing: value.playing, position: state.position, duration: state.duration, speed: state.speed, errorKey: state.errorKey);
      if (value.processingState == ProcessingState.completed) _playNextUnheard();
    }));
    ref.onDispose(() { for (final subscription in _subscriptions) { subscription.cancel(); } _player.dispose(); });
    return const ChatAudioState();
  }

  Future<void> toggle(ChatMessage message) async {
    try {
      if (state.messageId == message.id) { state.playing ? await _player.pause() : await _player.play(); return; }
      final path = message.mediaPath;
      if (path == null) return;
      _conversationId = message.conversationId;
      var url = await ref.read(chatRepositoryProvider).signedMediaUrl(path);
      try { await _player.setUrl(url); } catch (_) { url = await ref.read(chatRepositoryProvider).signedMediaUrl(path, refresh: true); await _player.setUrl(url); }
      state = ChatAudioState(messageId: message.id, duration: Duration(milliseconds: message.durationMs ?? 0), speed: state.speed);
      await _player.setSpeed(state.speed); await _player.play();
    } catch (_) { state = ChatAudioState(messageId: message.id, errorKey: 'chat_b.voice_unsupported'); }
  }

  Future<void> seek(Duration value) => _player.seek(value);
  Future<void> cycleSpeed() async { final speed = state.speed == 1 ? 1.5 : state.speed == 1.5 ? 2.0 : 1.0; await _player.setSpeed(speed); state = ChatAudioState(messageId: state.messageId, playing: state.playing, position: state.position, duration: state.duration, speed: speed, errorKey: state.errorKey); }

  Future<void> _playNextUnheard() async {
    final conversationId = _conversationId;
    final currentId = state.messageId;
    if (conversationId == null || currentId == null) return;
    final items = ref.read(messagesProvider(conversationId)).value?.items ?? const <ChatMessage>[];
    final currentIndex = items.indexWhere((item) => item.id == currentId);
    final heard = ref.read(listenedVoiceIdsProvider);
    final next = items.skip(currentIndex + 1).where((item) => item.kind == 'voice' && item.status != 'deleted' && !heard.contains(item.id)).firstOrNull;
    if (next != null) { ref.read(listenedVoiceIdsProvider.notifier).add(next.id); await toggle(next); }
  }
}

final chatAudioProvider = NotifierProvider<ChatAudioNotifier, ChatAudioState>(ChatAudioNotifier.new);
final listenedVoiceIdsProvider = NotifierProvider<ListenedVoiceIdsNotifier, Set<String>>(ListenedVoiceIdsNotifier.new);

class ListenedVoiceIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};
  void add(String id) => state = {...state, id};
}