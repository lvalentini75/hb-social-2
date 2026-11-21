import 'dart:async';
import 'dart:js_interop';

import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:web/web.dart' as web;

Future<Duration> readVideoDuration(PreparedUpload upload) async {
  final blob = web.Blob(<web.BlobPart>[upload.bytes.toJS].toJS, web.BlobPropertyBag(type: upload.contentType));
  final objectUrl = web.URL.createObjectURL(blob);
  final video = web.HTMLVideoElement()..preload = 'metadata';
  final completer = Completer<Duration>();

  void completeFromMetadata(web.Event _) {
    final seconds = video.duration;
    if (!seconds.isFinite || seconds <= 0) {
      completer.completeError(const AppException('errors.video_unreadable'));
      return;
    }
    completer.complete(Duration(milliseconds: (seconds * 1000).round()));
  }

  void completeWithError(web.Event _) {
    if (!completer.isCompleted) completer.completeError(const AppException('errors.video_unreadable'));
  }

  video.addEventListener('loadedmetadata', completeFromMetadata.toJS);
  video.addEventListener('error', completeWithError.toJS);
  video.src = objectUrl;
  video.load();
  try {
    return await completer.future.timeout(const Duration(seconds: 8), onTimeout: () => throw const AppException('errors.video_unreadable'));
  } on AppException {
    rethrow;
  } catch (_) {
    throw const AppException('errors.video_unreadable');
  } finally {
    video.pause();
    video.removeAttribute('src');
    video.load();
    web.URL.revokeObjectURL(objectUrl);
  }
}