import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/livekit_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/calls/data/calls_repository.dart';
import 'package:hb_social/features/calls/domain/call.dart';
import 'package:hb_social/features/live/providers/live_providers.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final callsRepositoryProvider = Provider<CallsRepository>((ref) => CallsRepository(ref.watch(supabaseClientProvider)));
final activeCallProvider = FutureProvider<AppCall?>((ref) => ref.watch(callsRepositoryProvider).active());
final callHistoryProvider = FutureProvider<List<AppCall>>((ref) => ref.watch(callsRepositoryProvider).history());
final callProvider = Provider.autoDispose.family<CallController, String>((ref, id) {
  final controller = CallController(id, ref.read(callsRepositoryProvider), ref.read(liveKitServiceProvider));
  ref.onDispose(controller.dispose);
  controller.initialize();
  return controller;
});

class CallController extends ChangeNotifier {
  final String callId;
  final CallsRepository repository;
  final LiveKitService liveKit;
  AppCall? call;
  CallToken? grant;
  Room? room;
  Object? error;
  bool loading = true;
  bool microphone = true;
  bool camera = true;
  bool speaker = false;
  RealtimeChannel? _channel;
  Timer? _ringTimer;

  CallController(this.callId, this.repository, this.liveKit);

  Future<void> initialize() async {
    try {
      call = await repository.detail(callId);
      _subscribe();
      if (call!.direction == 'outgoing' || call!.status == 'accepted') await connect();
      if (call!.status == 'ringing' && call!.direction == 'outgoing') _ringTimer = Timer(const Duration(seconds: 45), cancel);
    } catch (value) { error = value; }
    loading = false; notifyListeners();
  }

  Future<void> connect() async {
    grant ??= await repository.token(callId);
    room ??= await liveKit.connect(grant!.url, grant!.token, audio: true, video: call?.kind == 'video');
    camera = call?.kind == 'video';
    notifyListeners();
  }
  Future<void> answer() async { call = await repository.answer(callId); await connect(); notifyListeners(); }
  Future<void> decline() async { call = await repository.decline(callId); notifyListeners(); }
  Future<void> cancel() async { if (call?.status == 'ringing') call = await repository.cancel(callId); notifyListeners(); }
  Future<void> end() async { call = await repository.end(callId); await liveKit.dispose(); notifyListeners(); }
  Future<void> toggleMicrophone() async { microphone = !microphone; await liveKit.toggleMicrophone(microphone); notifyListeners(); }
  Future<void> toggleCamera() async { camera = !camera; await liveKit.toggleCamera(camera); notifyListeners(); }
  Future<void> toggleSpeaker() async { speaker = !speaker; await liveKit.setSpeaker(speaker); notifyListeners(); }

  void _subscribe() {
    final channel = repository.client.channel('call:$callId');
    channel.onPostgresChanges(event: PostgresChangeEvent.update, schema: 'public', table: 'calls', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: callId), callback: (_) => _reload());
    _channel = channel; channel.subscribe();
  }
  Future<void> _reload() async { call = await repository.detail(callId); if (call!.status == 'accepted' && room == null) await connect(); if (call!.terminal) await liveKit.dispose(); notifyListeners(); }

  @override void dispose() { _ringTimer?.cancel(); if (_channel != null) repository.client.removeChannel(_channel!); liveKit.dispose(); super.dispose(); }
}