import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/camera_capture.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/video_metadata_reader.dart';
import 'package:hb_social/core/services/video_poster_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/media_source_sheet.dart';
import 'package:hb_social/features/reels/domain/reel.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';

class ReelCreatePage extends ConsumerStatefulWidget {
  const ReelCreatePage({super.key});
  @override ConsumerState<ReelCreatePage> createState() => _ReelCreatePageState();
}

class _ReelCreatePageState extends ConsumerState<ReelCreatePage> {
  final caption = TextEditingController();
  final location = TextEditingController();
  PlatformFile? file;
  Uint8List? poster;
  Duration? duration;
  bool sensitive = false;
  bool working = false;
  double progress = 0;
  String? videoId;
  String? errorKey;
  Map<String, String> errorArgs = const {};
  CancelToken? cancelToken;

  @override void dispose() { caption.dispose(); location.dispose(); cancelToken?.cancel(); super.dispose(); }

  Future<void> _pick() async {
    final source = await showMediaSourceSheet(context, allowPhotoCapture: false, allowVideoCapture: true);
    if (source == null || !mounted) return;
    PlatformFile? selected;
    if (source == MediaSourceOption.library) {
      final result = await FilePicker.pickFiles(type: FileType.video, allowMultiple: false, withData: true);
      if (result == null || !mounted) return;
      selected = result.files.single;
    } else {
      final captured = await captureFromCamera(context, video: true);
      if (captured == null || !mounted) return;
      selected = PlatformFile(name: captured.name, size: captured.bytes.length, bytes: captured.bytes);
    }
    if (selected.bytes == null) { _error(const AppException('reels.errors.file_unreadable')); return; }
    setState(() { file = selected; duration = null; poster = null; errorKey = null; });
    try {
      final extension = selected.extension ?? 'mp4';
      final upload = PreparedUpload(bytes: selected.bytes!, extension: extension, contentType: _mime(extension));
      final values = await Future.wait<Object?>([readVideoDuration(upload), const VideoPosterService().extract(selected)]);
      final value = values.first as Duration;
      final allowance = await ref.read(reelUploadAllowanceProvider.future);
      if (value.inMilliseconds > allowance.maxSeconds * 1000) throw AppException('reels.errors.too_long_before_upload', namedArgs: {'seconds': '${value.inSeconds}', 'max': '${allowance.maxSeconds}'});
      if (mounted) setState(() { duration = value; poster = (values[1] as VideoPoster?)?.bytes; });
    } catch (error) { _error(error is AppException ? error : const AppException('reels.errors.duration_unavailable')); }
  }

  Future<void> _publish() async {
    final selected = file;
    if (selected?.bytes == null || duration == null || caption.text.length > 2200 || working) return;
    setState(() { working = true; progress = 0; errorKey = null; });
    try {
      final repository = ref.read(reelsRepositoryProvider);
      final grant = await repository.createUpload();
      videoId = grant.videoId;
      cancelToken = CancelToken();
      await repository.uploadTus(tus: grant.tus, bytes: selected!.bytes!, fileName: selected.name, mimeType: _mime(selected.extension ?? 'mp4'), onProgress: (value) { if (mounted) setState(() => progress = value); }, cancelToken: cancelToken);
      await repository.submit(videoId: grant.videoId, caption: caption.text, isSensitive: sensitive, locationName: location.text);
      ref.invalidate(myReelsProvider);
      if (mounted) { context.go(AppRoutes.reelsMine); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('reels.upload.processing'.tr()))); }
    } catch (error) { _error(error is AppException ? error : const AppException('reels.errors.upload_failed')); }
    if (mounted) setState(() => working = false);
  }

  Future<void> _cancel() async { cancelToken?.cancel(); final id = videoId; if (id != null) await ref.read(reelsRepositoryProvider).discard(id); if (mounted) setState(() { working = false; progress = 0; videoId = null; }); }
  void _error(AppException error) { if (mounted) setState(() { working = false; errorKey = error.messageKey; errorArgs = error.namedArgs; if (error.messageKey == 'reels.errors.too_long_before_upload') file = null; }); }
  String _mime(String extension) => extension.toLowerCase() == 'mov' ? 'video/quicktime' : 'video/mp4';

  @override Widget build(BuildContext context) {
    final allowance = ref.watch(reelUploadAllowanceProvider);
    return ColoredBox(color: LightModeColors.pageMobile, child: SafeArea(child: CustomScrollView(slivers: [SliverAppBar(title: Text('reels.create'.tr()), leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)), pinned: true), SliverPadding(padding: const EdgeInsets.all(AppSpacing.md), sliver: SliverList.list(children: [
      allowance.when(loading: () => const LinearProgressIndicator(), error: (_, __) => const SizedBox.shrink(), data: (value) => value.ok ? const SizedBox.shrink() : HBCard(child: Text('reels.errors.${value.reason}'.tr()))),
      HBCard(child: Column(children: [AspectRatio(aspectRatio: 9 / 16, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.media), child: poster == null ? ColoredBox(color: LightModeColors.surfaceSoft, child: Center(child: HBButton.soft(label: 'reels.upload.choose'.tr(), icon: Icons.video_library_outlined, onPressed: working ? null : _pick))) : Stack(fit: StackFit.expand, children: [Image.memory(poster!, fit: BoxFit.cover), const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64))]))), if (duration != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('reels.upload.duration'.tr(namedArgs: {'seconds': '${duration!.inSeconds}'})))])),
      const SizedBox(height: AppSpacing.md), HBCard(child: Column(children: [HBInput(controller: caption, label: 'reels.caption'.tr(), hint: 'reels.caption_hint'.tr(), maxLines: 5, maxLength: 2200, enabled: !working, onChanged: (_) => setState(() {})), const SizedBox(height: AppSpacing.sm), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('reels.sensitive.label'.tr()), value: sensitive, onChanged: working ? null : (value) => setState(() => sensitive = value)), HBInput(controller: location, label: 'reels.location'.tr(), hint: 'reels.location_hint'.tr(), enabled: !working)])),
      if (errorKey != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text(errorKey!.tr(namedArgs: errorArgs), style: AppText.body.copyWith(color: LightModeColors.danger))),
      if (working) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: progress, publishing: progress >= 1), const SizedBox(height: AppSpacing.sm), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: _cancel)],
      const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'reels.publish'.tr(), onPressed: file != null && duration != null && caption.text.length <= 2200 && !working && (allowance.value?.ok ?? false) ? _publish : null, isLoading: working),
    ]))])));
  }
}