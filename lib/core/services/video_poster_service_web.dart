import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/video_poster_result.dart';
import 'package:web/web.dart' as web;

Future<VideoPosterResult?> extractVideoPoster(PlatformFile source) async {
  final bytes = source.bytes;
  if (bytes == null) return null;
  final type = source.extension?.toLowerCase() == 'mov' ? 'video/quicktime' : 'video/mp4';
  final blob = web.Blob(<web.BlobPart>[bytes.toJS].toJS, web.BlobPropertyBag(type: type));
  final objectUrl = web.URL.createObjectURL(blob);
  final video = web.HTMLVideoElement()
    ..muted = true
    ..autoplay = false
    ..preload = 'metadata'
    ..setAttribute('playsinline', '')
    ..style.display = 'none';
  web.document.body?.append(video);
  final stopwatch = Stopwatch()..start();
  try {
    final loaded = _event(video, 'loadeddata');
    video.src = objectUrl;
    video.load();
    await loaded.timeout(_remaining(stopwatch));
    final durationMs = (video.duration * 1000).round();
    if (durationMs <= 0) return null;
    VideoPosterResult? brightest;
    var brightestLuminance = -1.0;
    for (final timeMs in _candidateTimes(durationMs)) {
      final seeked = _event(video, 'seeked');
      video.currentTime = timeMs / 1000;
      await seeked.timeout(_remaining(stopwatch));
      final width = video.videoWidth;
      final height = video.videoHeight;
      if (width <= 0 || height <= 0) continue;
      final scale = width > height ? (1280 / width).clamp(0.0, 1.0) : (1280 / height).clamp(0.0, 1.0);
      final outputWidth = (width * scale).round();
      final outputHeight = (height * scale).round();
      final canvas = web.HTMLCanvasElement()..width = outputWidth..height = outputHeight;
      canvas.context2D.drawImageScaled(video, 0, 0, outputWidth.toDouble(), outputHeight.toDouble());
      final sample = web.HTMLCanvasElement()..width = 32..height = 32;
      sample.context2D.drawImageScaled(canvas, 0, 0, 32, 32);
      final luminance = _meanLuminance(sample.context2D.getImageData(0, 0, 32, 32).data.toDart);
      final jpeg = await _jpeg(canvas).timeout(_remaining(stopwatch));
      if (jpeg == null) continue;
      final candidate = VideoPosterResult(bytes: jpeg, width: outputWidth, height: outputHeight, durationMs: durationMs);
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
    video.pause();
    video.removeAttribute('src');
    video.load();
    video.remove();
    web.URL.revokeObjectURL(objectUrl);
  }
}

Duration _remaining(Stopwatch stopwatch) {
  final milliseconds = 8000 - stopwatch.elapsedMilliseconds;
  if (milliseconds <= 0) throw TimeoutException('video poster timeout');
  return Duration(milliseconds: milliseconds);
}

List<int> _candidateTimes(int durationMs) => const [300, 1000, 2000, 4000, 8000].where((time) => time <= durationMs).toList()..addAll(durationMs < 300 ? [durationMs] : const []);

Future<void> _event(web.EventTarget target, String name) {
  final completer = Completer<void>();
  late JSFunction listener;
  listener = ((web.Event _) {
    target.removeEventListener(name, listener);
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  target.addEventListener(name, listener);
  return completer.future;
}

double _meanLuminance(Uint8ClampedList pixels) {
  var total = 0.0;
  for (var index = 0; index < pixels.length; index += 4) total += (0.2126 * pixels[index] + 0.7152 * pixels[index + 1] + 0.0722 * pixels[index + 2]) / 255;
  return total / (pixels.length / 4);
}

Future<Uint8List?> _jpeg(web.HTMLCanvasElement canvas) {
  final completer = Completer<Uint8List?>();
  canvas.toBlob(((web.Blob? blob) {
    if (blob == null) {
      completer.complete(null);
      return;
    }
    blob.arrayBuffer().toDart.then((buffer) {
      completer.complete(buffer.toDart.asUint8List());
    }).catchError((error) {
      if (!completer.isCompleted) completer.completeError(error);
    });
  }).toJS, 'image/jpeg', 0.82.toJS);
  return completer.future;
}