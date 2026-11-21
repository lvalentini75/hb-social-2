import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hb_social/core/services/video_poster_result.dart';
import 'package:hb_social/core/services/video_poster_service_native.dart'
    if (dart.library.js_interop) 'package:hb_social/core/services/video_poster_service_web.dart' as platform;

class VideoPoster {
  final Uint8List bytes;
  final int width;
  final int height;
  final int durationMs;

  const VideoPoster({required this.bytes, required this.width, required this.height, required this.durationMs});
}

/// Extracts one representative JPEG frame without exposing platform details.
class VideoPosterService {
  const VideoPosterService();

  Future<VideoPoster?> extract(PlatformFile file) async {
    final result = await platform.extractVideoPoster(file);
    return result == null ? null : VideoPoster(bytes: result.bytes, width: result.width, height: result.height, durationMs: result.durationMs);
  }
}