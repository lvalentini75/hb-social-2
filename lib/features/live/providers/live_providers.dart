import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/services/livekit_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/live/data/live_repository.dart';
import 'package:hb_social/features/live/domain/live_models.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final liveRepositoryProvider = Provider<LiveRepository>((ref) => LiveRepository(ref.watch(supabaseClientProvider)));
final liveKitServiceProvider = Provider<LiveKitService>((ref) { final service = LiveKitService(); ref.onDispose(service.dispose); return service; });
final liveActiveProvider = AsyncNotifierProvider<LiveActiveNotifier, List<LiveStream>>(LiveActiveNotifier.new);
final liveDetailProvider = FutureProvider.family<LiveStream, String>((ref, id) => ref.watch(liveRepositoryProvider).detail(id));
final myLiveStreamsProvider = FutureProvider<List<LiveStream>>((ref) => ref.watch(liveRepositoryProvider).mine());
final liveRoomProvider = Provider.autoDispose.family<LiveRoomController, String>((ref, id) {
  final controller = LiveRoomController(id, ref.read(liveRepositoryProvider), ref.read(liveKitServiceProvider));
  ref.onDispose(controller.dispose);
  controller.initialize();
  return controller;
});

class LiveActiveNotifier extends AsyncNotifier<List<LiveStream>> {
  Timer? _timer;
  @override Future<List<LiveStream>> build() async {
    ref.onDispose(() => _timer?.cancel());
    final flags = await ref.watch(featureFlagsProvider.future);
    if (flags['live'] != true) return const [];
    final country = ref.watch(userSettingsProvider).countryCode;
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    return ref.watch(liveRepositoryProvider).active(country: country);
  }
  Future<void> refresh() async { try { state = AsyncData(await ref.read(liveRepositoryProvider).active(country: ref.read(userSettingsProvider).countryCode)); } catch (error, stack) { state = AsyncError(error, stack); } }
}

class LiveRoomController extends ChangeNotifier {
  final String streamId;
  final LiveRepository repository;
  final LiveKitService liveKit;
  LiveStream? stream;
  LiveToken? grant;
  Room? room;
  List<LiveMessage> messages = const [];
  List<Map<String, dynamic>> viewers = const [];
  Object? error;
  bool loading = true;
  bool sending = false;
  RealtimeChannel? _channel;

  LiveRoomController(this.streamId, this.repository, this.liveKit);

  Future<void> initialize() async {
    try {
      stream = await repository.detail(streamId);
      if (stream!.status == 'live') {
        grant = await repository.token(streamId);
        room = await liveKit.connect(grant!.url, grant!.token, audio: stream!.isHost, video: stream!.isHost);
        messages = await repository.messages(streamId);
        if (stream!.isHost) viewers = await repository.viewers(streamId);
        _subscribe();
      }
    } catch (value) { error = value; }
    loading = false;
    notifyListeners();
  }

  Future<void> send(String body) async {
    if (sending || body.trim().isEmpty) return;
    sending = true; notifyListeners();
    try { await repository.sendMessage(streamId, body); }
    finally { sending = false; notifyListeners(); }
  }

  Future<void> moderate(String userId, String action) async { if (action == 'remove') { await repository.kick(streamId, userId); } else { await repository.moderate(streamId, userId, action); } await refreshViewers(); }
  Future<void> refreshViewers() async { viewers = await repository.viewers(streamId); notifyListeners(); }

  void _subscribe() {
    final channel = repository.client.channel('live:$streamId');
    final filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'stream_id', value: streamId);
    channel
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'live_messages', filter: filter, callback: (_) => _reloadMessages())
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'live_messages', filter: filter, callback: (_) => _reloadMessages())
      .onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'live_streams', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: streamId), callback: (_) => _reloadStream());
    _channel = channel;
    channel.subscribe();
  }
  Future<void> _reloadMessages() async { messages = await repository.messages(streamId); notifyListeners(); }
  Future<void> _reloadStream() async { stream = await repository.detail(streamId); if (stream!.isHost) await refreshViewers(); notifyListeners(); }

  @override void dispose() {
    if (_channel != null) repository.client.removeChannel(_channel!);
    repository.leave(streamId).catchError((_) {});
    liveKit.dispose();
    super.dispose();
  }
}