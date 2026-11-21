import 'package:flutter/widgets.dart';
import 'package:hb_social/core/services/camera_capture_result.dart';
import 'package:hb_social/core/services/camera_capture_native.dart'
    if (dart.library.js_interop) 'package:hb_social/core/services/camera_capture_web.dart' as platform;

export 'package:hb_social/core/services/camera_capture_result.dart';

/// Captures one photo (or video on mobile) using the current platform camera.
Future<CapturedMedia?> captureFromCamera(BuildContext context, {bool video = false}) => platform.captureFromCamera(context, video: video);
