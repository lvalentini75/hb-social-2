import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveKitService {
  Room? _room;
  CameraPosition _camera = CameraPosition.front;

  Room? get activeRoom => _room;
  bool get hasActiveRoom => _room != null;

  Future<Room> connect(String url, String token, {required bool audio, required bool video, CameraPosition camera = CameraPosition.front}) async {
    await dispose();
    await _ensurePermissions(audio: audio, video: video);
    _camera = camera;
    final room = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
    try {
      await room.connect(url, token, connectOptions: const ConnectOptions(autoSubscribe: true));
      _room = room;
      if (audio) await room.localParticipant?.setMicrophoneEnabled(true);
      if (video) await room.localParticipant?.setCameraEnabled(true, cameraCaptureOptions: CameraCaptureOptions(cameraPosition: camera));
      return room;
    } catch (_) {
      await room.dispose();
      throw const AppException('live.errors.connection_failed');
    }
  }

  Future<void> _ensurePermissions({required bool audio, required bool video}) async {
    if (kIsWeb) return;
    if (audio && !await Permission.microphone.request().isGranted) throw const AppException('live.errors.microphone_permission');
    if (video && !await Permission.camera.request().isGranted) throw const AppException('live.errors.camera_permission');
  }

  Future<void> toggleMicrophone(bool enabled) async => _room?.localParticipant?.setMicrophoneEnabled(enabled);
  Future<void> toggleCamera(bool enabled) async => _room?.localParticipant?.setCameraEnabled(enabled, cameraCaptureOptions: CameraCaptureOptions(cameraPosition: _camera));
  Future<void> switchCamera() async {
    _camera = _camera == CameraPosition.front ? CameraPosition.back : CameraPosition.front;
    await _room?.localParticipant?.setCameraEnabled(false);
    await _room?.localParticipant?.setCameraEnabled(true, cameraCaptureOptions: CameraCaptureOptions(cameraPosition: _camera));
  }
  Future<void> setSpeaker(bool enabled) => Hardware.instance.setSpeakerphoneOn(enabled);

  Future<void> dispose() async {
    final room = _room;
    _room = null;
    if (room == null) return;
    await room.disconnect();
    await room.dispose();
  }
}