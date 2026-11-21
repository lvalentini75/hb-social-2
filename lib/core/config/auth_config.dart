import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/services/platform_config_service.dart';

class AuthConfig {
  const AuthConfig._();

  static String get redirectUrl => kIsWeb ? '${Uri.base.origin}/auth/callback' : 'huntingbook://login-callback';

  static String get platformKey {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  static bool isProviderVisible(AuthPlatformConfig config, String provider) {
    final value = config.providers[provider];
    return value != null && value.enabled && value.platforms.contains(platformKey);
  }
}