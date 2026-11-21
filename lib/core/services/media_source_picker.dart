import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/camera_capture.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/widgets/media_source_sheet.dart';

/// Single entry point for every photo and video selection: it always asks the
/// user whether the media comes from the device library or from the camera.
class MediaSourcePicker {
  const MediaSourcePicker._();

  /// Raw image bytes used by the croppers (avatars, covers, sightings).
  static Future<Uint8List?> imageBytes(BuildContext context, MediaUploadService service) async {
    final source = await showMediaSourceSheet(context);
    if (source == null) return null;
    if (source == MediaSourceOption.library) return service.pickImageBytes();
    if (!context.mounted) return null;
    final captured = await captureFromCamera(context);
    if (captured == null) return null;
    return service.prepareCapturedImage(captured).bytes;
  }

  /// One prepared image resized to [maxDimension].
  static Future<PreparedUpload?> singleImage(BuildContext context, MediaUploadService service, {required int maxDimension}) async {
    final source = await showMediaSourceSheet(context);
    if (source == null) return null;
    if (source == MediaSourceOption.library) return service.pickAndPrepareImage(maxDimension: maxDimension);
    if (!context.mounted) return null;
    final captured = await captureFromCamera(context);
    if (captured == null) return null;
    return service.prepareCapturedImage(captured, maxDimension: maxDimension);
  }

  /// Multiple post images, or one camera shot.
  static Future<List<PreparedUpload>> postImages(BuildContext context, MediaUploadService service, {required int remaining}) async {
    if (remaining <= 0) return const [];
    final source = await showMediaSourceSheet(context);
    if (source == null) return const [];
    if (source == MediaSourceOption.library) return service.pickPostImages(remaining: remaining);
    if (!context.mounted) return const [];
    final captured = await captureFromCamera(context);
    if (captured == null) return const [];
    return [service.prepareCapturedImage(captured)];
  }

  /// One video from the device files or recorded with the camera.
  static Future<PreparedUpload?> video(BuildContext context, MediaUploadService service, {int maxBytes = 100 * 1024 * 1024}) async {
    final source = await showMediaSourceSheet(context, allowPhotoCapture: false, allowVideoCapture: true);
    if (source == null) return null;
    if (source == MediaSourceOption.library) return service.pickPostVideo();
    if (!context.mounted) return null;
    final captured = await captureFromCamera(context, video: true);
    if (captured == null) return null;
    return service.prepareCapturedVideo(captured, maxBytes: maxBytes);
  }

  /// Album and diary media: images and videos together.
  static Future<({List<PreparedUpload> uploads, int tooLarge})> albumMedia(BuildContext context, MediaUploadService service, {required int limit}) async {
    const empty = (uploads: <PreparedUpload>[], tooLarge: 0);
    if (limit <= 0) throw const AppException('albums.errors.album_full');
    final source = await showMediaSourceSheet(context, allowVideoCapture: true);
    if (source == null) return empty;
    if (source == MediaSourceOption.library) return service.pickAlbumMedia(limit: limit);
    if (!context.mounted) return empty;
    final captured = await captureFromCamera(context, video: source == MediaSourceOption.cameraVideo);
    if (captured == null) return empty;
    final upload = captured.isVideo ? await service.prepareCapturedVideo(captured) : service.prepareCapturedImage(captured);
    return (uploads: [upload], tooLarge: 0);
  }
}
