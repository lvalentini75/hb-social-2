import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

String get currentPlatformName {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}