import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/camera_capture.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/video_metadata_reader.dart';
import 'package:hb_social/core/services/video_poster_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/media_source_sheet.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/stories/presentation/story_photo_editor.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:uuid/uuid.dart';

Future<void> showStoryComposer(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  if (container.read(supabaseClientProvider).auth.currentUser == null) {
    context.go(AppRoutes.login);
    return;
  }
  final mobile = MediaQuery.sizeOf(context).width < 700;
  final published = mobile
      ? await showModalBottomSheet<bool>(context: context, useRootNavigator: true, isScrollControlled: true, isDismissible: false, enableDrag: false, useSafeArea: true, backgroundColor: Colors.transparent, builder: (_) => const FractionallySizedBox(heightFactor: 1, child: StoryComposer()))
      : await showDialog<bool>(context: context, useRootNavigator: true, barrierDismissible: false, builder: (_) => const Dialog(clipBehavior: Clip.antiAlias, child: SizedBox(width: 480, child: StoryComposer())));
  if (published == true && context.mounted) {
    container.invalidate(storyTrayProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('story_composer.published'.tr())));
  }
}

class StoryComposer extends ConsumerStatefulWidget {
  const StoryComposer({super.key});

  @override
  ConsumerState<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends ConsumerState<StoryComposer> {
  static const _extensions = ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov'];
  static const _maxImageBytes = 50 * 1024 * 1024;
  static const _maxVideoBytes = 100 * 1024 * 1024;
  final _captionController = TextEditingController();
  final _photoEditorController = StoryPhotoEditorController();
  StorySelectedMedia? _media;
  bool _analyzingVideo = false;
  bool _sending = false;
  bool _publishing = false;
  double _uploadProgress = 0;
  String _step = 'pick';
  String? _errorKey;
  Map<String, String> _errorArgs = const {};

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_sending || _analyzingVideo) return;
    _step = 'pick';
    try {
      final source = await showMediaSourceSheet(context, allowVideoCapture: true);
      if (source == null || !mounted) return;
      if (source != MediaSourceOption.library) {
        await _capture(video: source == MediaSourceOption.cameraVideo);
        return;
      }
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: _extensions, allowMultiple: false, withData: true);
      if (result == null || !mounted) return;
      final file = result.files.single;
      final posterFuture = const VideoPosterService().extract(file);
      final bytes = file.bytes;
      setState(() { _media = null; _errorKey = null; _errorArgs = const {}; });
      if (bytes == null) throw const AppException('errors.file_unreadable');
      final extension = (file.extension ?? file.name.split('.').last).toLowerCase();
      if (!_extensions.contains(extension)) throw const AppException('errors.file_type_not_allowed');
      final kind = const {'mp4', 'mov'}.contains(extension) ? 'video' : 'image';
      final maxBytes = kind == 'video' ? _maxVideoBytes : _maxImageBytes;
      if (bytes.length > maxBytes) throw const AppException('errors.file_too_large');
      final selected = StorySelectedMedia(bytes: bytes, name: file.name, extension: extension, contentType: _contentType(extension), kind: kind);
      setState(() { _media = selected; _analyzingVideo = kind == 'video'; });
      if (kind == 'video') await _readMetadata(selected, posterFuture);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _capture({required bool video}) async {
    final captured = await captureFromCamera(context, video: video);
    if (captured == null || !mounted) return;
    if (captured.bytes.length > (captured.isVideo ? _maxVideoBytes : _maxImageBytes)) throw const AppException('errors.file_too_large');
    final selected = StorySelectedMedia(bytes: captured.bytes, name: captured.name, extension: captured.extension, contentType: captured.contentType, kind: captured.isVideo ? 'video' : 'image');
    setState(() { _media = selected; _errorKey = null; _errorArgs = const {}; _analyzingVideo = captured.isVideo; });
    if (captured.isVideo) {
      final poster = const VideoPosterService().extract(PlatformFile(name: captured.name, size: captured.bytes.length, bytes: captured.bytes));
      await _readMetadata(selected, poster);
    }
  }

  Future<void> _readMetadata(StorySelectedMedia selected, Future<VideoPoster?> posterFuture) async {
    _step = 'metadata';
    try {
      final upload = PreparedUpload(bytes: selected.bytes, extension: selected.extension, contentType: selected.contentType);
      final results = await Future.wait<Object?>([readVideoDuration(upload).timeout(const Duration(seconds: 15)), posterFuture]);
      final duration = results[0] as Duration;
      final poster = results[1] as VideoPoster?;
      if (duration > const Duration(minutes: 2)) {
        if (mounted) setState(() => _media = null);
        throw AppException('errors.video_too_long', namedArgs: {'duration': _formatDuration(duration)});
      }
      if (mounted) setState(() { _media = selected.withVideoData(duration, poster); _analyzingVideo = false; });
    } catch (error) {
      if (error is AppException && error.messageKey == 'errors.video_too_long') {
        _fail(error);
      } else {
        _fail(const AppException('story_composer.duration_unavailable'));
      }
    }
  }

  Future<void> _publish() async {
    final selected = _media;
    final profile = ref.read(currentProfileProvider).value;
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (selected == null || profile == null || user == null || _analyzingVideo || _captionController.text.length > 300) return;
    setState(() { _sending = true; _publishing = false; _uploadProgress = 0; _errorKey = null; _errorArgs = const {}; });

    PreparedUpload upload;
    if (selected.kind == 'image') {
      _step = 'resize';
      try {
        final editedBytes = await _photoEditorController.exportImage();
        upload = ref.read(mediaUploadServiceProvider).prepareStoryImage(editedBytes);
      } catch (error) {
        _fail(error is AppException ? error : const AppException('errors.image_processing_failed'));
        return;
      }
    } else {
      upload = PreparedUpload(bytes: selected.bytes, extension: selected.extension, contentType: selected.contentType, durationMs: selected.duration?.inMilliseconds);
    }

    final path = '${user.id}/${const Uuid().v4()}.${upload.extension}';
    final progressVisibleSince = DateTime.now();
    UploadedMedia uploaded;
    UploadedMedia? posterUploaded;
    _step = 'upload';
    try {
      final posterBytes = selected.poster?.bytes;
      final totalBytes = upload.bytes.length + (posterBytes?.length ?? 0);
      if (posterBytes != null) {
        final posterProgress = UploadProgress();
        final subscription = posterProgress.stream.listen((value) { if (mounted) setState(() => _uploadProgress = value * posterBytes.length / totalBytes); });
        try {
          posterUploaded = await ref.read(mediaUploadServiceProvider).uploadPoster(bucket: 'story-media', bytes: posterBytes, progress: posterProgress);
        } finally {
          await subscription.cancel();
          await posterProgress.close();
        }
      }
      uploaded = await ref.read(mediaUploadServiceProvider).uploadBytes(bucket: 'story-media', path: path, bytes: upload.bytes, contentType: upload.contentType, onProgress: (value) {
        if (mounted) setState(() => _uploadProgress = ((posterBytes?.length ?? 0) + value * upload.bytes.length) / totalBytes);
      });
    } catch (error) {
      if (posterUploaded != null) await ref.read(mediaUploadServiceProvider).delete('story-media', posterUploaded.path).catchError((_) {});
      _fail(error);
      return;
    }

    final remaining = const Duration(milliseconds: 800) - DateTime.now().difference(progressVisibleSince);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;
    setState(() { _uploadProgress = 1; _publishing = true; });

    _step = 'insert';
    try {
      await ref.read(storyRepositoryProvider).publish(countryCode: profile.countryCode, kind: selected.kind, path: uploaded.path, thumbnailPath: posterUploaded?.path, caption: _captionController.text);
    } catch (error) {
      await ref.read(mediaUploadServiceProvider).delete('story-media', uploaded.path).catchError((Object cleanupError) {
        debugPrint('[story] insert cleanup: $cleanupError');
      });
      if (posterUploaded != null) await ref.read(mediaUploadServiceProvider).delete('story-media', posterUploaded.path).catchError((_) {});
      _fail(error);
      return;
    }

    _step = 'close';
    try {
      if (mounted) context.pop(true);
    } catch (error) {
      _fail(error);
    }
  }

  void _close() {
    _step = 'close';
    try {
      context.pop(false);
    } catch (error) {
      _fail(error);
    }
  }

  void _fail(Object error) {
    final failure = AppException.from(error);
    debugPrint('[story] $_step: $error');
    if (!mounted) return;
    setState(() {
      _sending = false;
      _publishing = false;
      _analyzingVideo = false;
      _errorKey = failure.messageKey;
      _errorArgs = failure.namedArgs;
    });
  }

  String _contentType(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'mov' => 'video/quicktime',
    _ => 'video/mp4',
  };

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _media != null && !_sending && !_analyzingVideo && _captionController.text.length <= 300;
    return PopScope(
      canPop: !_sending,
      child: Material(
        color: LightModeColors.lightSurface,
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [Expanded(child: Text('story_composer.title'.tr(), style: context.textStyles.titleLarge)), HBButton.icon(icon: Icons.close_rounded, onPressed: _sending ? null : _close)])),
          const Divider(height: 1),
          Expanded(child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
            AspectRatio(aspectRatio: 9 / 16, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: ColoredBox(color: Colors.black, child: _media == null
                ? StoryMediaPicker(onTap: _pick)
                : _media!.kind == 'image'
                    ? StoryPhotoEditor(key: ValueKey(_media), imageBytes: _media!.bytes, controller: _photoEditorController, enabled: !_sending)
                    : StorySelectedPreview(media: _media!, analyzing: _analyzingVideo)))),
            if (_errorKey != null) ...[const SizedBox(height: AppSpacing.sm), Text(_errorKey!.tr(namedArgs: _errorArgs), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
            if (_media?.kind == 'video' && !_analyzingVideo && _errorKey == null) ...[const SizedBox(height: AppSpacing.sm), Text('story_composer.video_details'.tr(namedArgs: {'duration': _formatDuration(_media!.duration!), 'size': _media!.sizeLabel}), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))],
            const SizedBox(height: AppSpacing.xs),
            Text('story_composer.video_limits'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            HBButton.soft(label: 'story_composer.choose_media'.tr(), icon: Icons.add_photo_alternate_outlined, onPressed: _sending || _analyzingVideo ? null : _pick),
            const SizedBox(height: AppSpacing.md),
            HBInput(controller: _captionController, label: 'story_composer.caption'.tr(), hint: 'story_composer.caption_hint'.tr(), maxLines: 3, maxLength: 300, enabled: !_sending, onChanged: (_) => setState(() {})),
            if (_sending) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _uploadProgress, publishing: _publishing)],
          ])),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: SizedBox(width: double.infinity, child: HBButton.primary(label: 'story_composer.publish'.tr(), onPressed: canPublish ? _publish : null, isLoading: _sending))),
        ])),
      ),
    );
  }
}

class StorySelectedMedia {
  final Uint8List bytes;
  final String name;
  final String extension;
  final String contentType;
  final String kind;
  final Duration? duration;
  final VideoPoster? poster;

  const StorySelectedMedia({required this.bytes, required this.name, required this.extension, required this.contentType, required this.kind, this.duration, this.poster});

  String get sizeLabel => '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
  StorySelectedMedia withVideoData(Duration value, VideoPoster? poster) => StorySelectedMedia(bytes: bytes, name: name, extension: extension, contentType: contentType, kind: kind, duration: value, poster: poster);
}

class StoryMediaPicker extends StatelessWidget {
  final VoidCallback onTap;

  const StoryMediaPicker({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Center(child: HBButton.soft(label: 'story_composer.choose_media'.tr(), icon: Icons.add_photo_alternate_outlined, onPressed: onTap));
}

/// Memory-only preview used before a story is uploaded.
class StorySelectedPreview extends StatelessWidget {
  final StorySelectedMedia media;
  final bool analyzing;

  const StorySelectedPreview({super.key, required this.media, required this.analyzing});

  @override
  Widget build(BuildContext context) {
    if (media.kind == 'image') return Image.memory(media.bytes, fit: BoxFit.contain);
    return Stack(fit: StackFit.expand, children: [
      if (media.poster != null) Image.memory(media.poster!.bytes, fit: BoxFit.cover) else const ColoredBox(color: LightModeColors.lightBackgroundSoft),
      Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (analyzing) const CircularProgressIndicator(color: Colors.white) else const Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 64),
      const SizedBox(height: AppSpacing.md),
      Text(analyzing ? 'story_composer.analyzing_video'.tr() : media.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white)),
      const SizedBox(height: AppSpacing.xs),
      Text(media.sizeLabel, style: context.textStyles.bodySmall?.copyWith(color: Colors.white70)),
      ]))),
    ]);
  }
}