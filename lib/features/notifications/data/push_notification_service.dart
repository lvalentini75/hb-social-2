import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  static const vapidKey = 'BBW-mPndW7S2foR4VXl6eYDBD-cmFyYGRvCshY8PsTPOMuDVz4HTWnd_RnhhAYzu1xpiXystkgOsVZCQ-KAgzyE';
  final SupabaseClient _client;

  const PushNotificationService(this._client);

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool get isSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  Future<String?> registerCurrentDevice() async {
    if (!isSupported || _client.auth.currentUser == null) return null;
    try {
      final permission = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      if (permission.authorizationStatus == AuthorizationStatus.denied) return null;
      final token = await _messaging.getToken(vapidKey: kIsWeb ? vapidKey : null);
      if (token == null || token.isEmpty) return null;
      await registerToken(token);
      return token;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> registerToken(String token) async {
    if (_client.auth.currentUser == null) return;
    try {
      await _client.rpc('register_push_token', params: {'p_token': token, 'p_platform': kIsWeb ? 'web' : 'android'});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (!isSupported || _client.auth.currentUser == null) return;
    try {
      final token = await _messaging.getToken(vapidKey: kIsWeb ? vapidKey : null);
      if (token != null && token.isNotEmpty) await _client.rpc('unregister_push_token', params: {'p_token': token});
    } catch (_) {
      // Logout must remain available if token cleanup cannot reach the backend.
    }
  }
}