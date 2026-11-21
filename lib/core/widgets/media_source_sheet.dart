import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// The origin chosen by the user before any photo or video upload.
enum MediaSourceOption { library, cameraPhoto, cameraVideo }

/// Asks where the media comes from: device files or the camera/webcam.
/// Returns null when the user dismisses the sheet.
Future<MediaSourceOption?> showMediaSourceSheet(BuildContext context, {bool allowVideoCapture = false, bool allowPhotoCapture = true}) async {
  final cameraVideo = allowVideoCapture && !kIsWeb;
  if (!allowPhotoCapture && !cameraVideo) return MediaSourceOption.library;
  return showModalBottomSheet<MediaSourceOption>(
    context: context,
    showDragHandle: true,
    useRootNavigator: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm), child: Text('media_source.title'.tr(), style: Theme.of(sheetContext).textTheme.titleMedium)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text((kIsWeb ? 'media_source.library_web' : 'media_source.library').tr()), onTap: () => sheetContext.pop(MediaSourceOption.library)),
            if (allowPhotoCapture) ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text((kIsWeb ? 'media_source.camera_web' : 'media_source.camera').tr()), onTap: () => sheetContext.pop(MediaSourceOption.cameraPhoto)),
            if (cameraVideo) ListTile(leading: const Icon(Icons.videocam_outlined), title: Text('media_source.record_video'.tr()), onTap: () => sheetContext.pop(MediaSourceOption.cameraVideo)),
          ],
        ),
      ),
    ),
  );
}
