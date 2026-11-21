import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/video_poster_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<VideoPosterResult?> extractVideoPoster(PlatformFile source) async {
  final bytes = source.bytes;
  if (bytes == null) return null;
  File? file;
  VideoPlayerController? controller;
  final stopwatch = Stopwatch()..start();
  try {
    final directory = await getTemporaryDirectory();
    final extension = (source.extension ?? 'mp4').toLowerCase();
    file = File('${directory.path}/hb_poster_${DateTime.now().microsecondsSinceEpoch}.$extension');
    await file.writeAsBytes(bytes, flush: true);
    controller = VideoPlayerController.file(file);
    await controller.initialize().timeout(_remaining(stopwatch));
    final durationMs = controller.value.duration.inMilliseconds;
    if (durationMs <= 0) return null;
    VideoPosterResult? brightest;
    var brightestLuminance = -1.0;
    for (final timeMs in _candidateTimes(durationMs)) {
      final frame = await VideoThumbnail.thumbnailData(video: file.path, imageFormat: ImageFormat.JPEG, maxWidth: 1280, quality: 82, timeMs: timeMs).timeout(_remaining(stopwatch));
      if (frame == null || frame.isEmpty) continue;
      final decoded = await _decode(frame).timeout(_remaining(stopwatch));
      final luminance = await _meanLuminance(decoded.image).timeout(_remaining(stopwatch));
      final candidate = VideoPosterResult(bytes: frame, width: decoded.image.width, height: decoded.image.height, durationMs: durationMs);
      decoded.image.dispose();
      if (luminance > brightestLuminance) {
        brightestLuminance = luminance;
        brightest = candidate;
      }
      if (luminance >= 0.08) return candidate;
    }
    return brightest;
  } catch (error) {
    debugPrint('[video-poster] extraction failed: $error');
    return null;
  } finally {
    await controller?.dispose();
    if (file != null && await file.exists()) await file.delete();
  }
}

Duration _remaining(Stopwatch stopwatch) {
  final milliseconds = 8000 - stopwatch.elapsedMilliseconds;
  if (milliseconds <= 0) throw TimeoutException('video poster timeout');
  return Duration(milliseconds: milliseconds);
}

List<int> _candidateTimes(int durationMs) => const [300, 1000, 2000, 4000, 8000].where((time) => time <= durationMs).toList()..addAll(durationMs < 300 ? [durationMs] : const []);

Future<({ui.Image image})> _decode(Uint8List bytes) async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return (image: await completer.future);
}

Future<double> _meanLuminance(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return 0;
  final pixels = data.buffer.asUint8List();
  final stepX = (image.width / 32).ceil().clamp(1, image.width);
  final stepY = (image.height / 32).ceil().clamp(1, image.height);
  var total = 0.0;
  var count = 0;
  for (var y = 0; y < image.height; y += stepY) {
    for (var x = 0; x < image.width; x += stepX) {
      final offset = (y * image.width + x) * 4;
      total += (0.2126 * pixels[offset] + 0.7152 * pixels[offset + 1] + 0.0722 * pixels[offset + 2]) / 255;
      count++;
    }
  }
  return count == 0 ? 0 : total / count;
}