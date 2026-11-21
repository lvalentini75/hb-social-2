import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/diary/data/diary_repository.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class OutingMediaPanel extends ConsumerStatefulWidget {
  final String outingId;
  final bool editable;
  const OutingMediaPanel({super.key, required this.outingId, required this.editable});
  @override
  ConsumerState<OutingMediaPanel> createState() => _OutingMediaPanelState();
}

class _OutingMediaPanelState extends ConsumerState<OutingMediaPanel> {
  bool _uploading = false;
  double _progress = 0;

  Future<void> _upload() async {
    setState(() { _uploading = true; _progress = 0; });
    final uploadedPaths = <String>[];
    try {
      final outing = await ref.read(outingProvider(widget.outingId).future);
      final remaining = 30 - (outing?.media.length ?? 0);
      if (remaining <= 0) throw const AppException('diary.errors.media_too_many');
      final selected = await MediaSourcePicker.albumMedia(context, ref.read(mediaUploadServiceProvider), limit: remaining.clamp(0, 10));
      if (selected.uploads.isEmpty) return;
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId == null) throw const AppException('errors.login_required');
      final service = ref.read(mediaUploadServiceProvider);
      final items = <OutingMediaInput>[];
      for (var index = 0; index < selected.uploads.length; index++) {
        var upload = selected.uploads[index];
        if (upload.mediaKind != 'video') {
          final crop = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('diary.media.crop_title'.tr()), content: Text('diary.media.crop_message'.tr()), actions: [HBButton.ghost(label: 'diary.media.keep_original'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'diary.media.crop'.tr(), onPressed: () => dialogContext.pop(true))]));
          if (crop == true && mounted) {
            final bytes = await HBImageCropper.show(context, bytes: upload.bytes, aspectRatio: 4 / 3, outputWidth: 1600, outputHeight: 1200);
            if (bytes != null) upload = service.prepareJpeg(bytes);
          }
        }
        final base = '$userId/${widget.outingId}/${const Uuid().v4()}';
        final mediaPath = '$base.${upload.extension}';
        final media = await service.uploadBytes(bucket: 'diary-media', path: mediaPath, bytes: upload.bytes, contentType: upload.contentType, isPublic: false, onProgress: (value) { if (mounted) setState(() => _progress = (index + value * .8) / selected.uploads.length); });
        uploadedPaths.add(media.path);
        String? thumbnailPath;
        if (upload.poster != null) {
          thumbnailPath = '${base}_poster.jpg';
          await service.uploadBytes(bucket: 'diary-media', path: thumbnailPath, bytes: upload.poster!.bytes, contentType: 'image/jpeg', isPublic: false, onProgress: (value) { if (mounted) setState(() => _progress = (index + .8 + value * .2) / selected.uploads.length); });
          uploadedPaths.add(thumbnailPath);
        }
        items.add(OutingMediaInput(path: media.path, kind: upload.mediaKind == 'video' ? 'video' : 'image', width: upload.width, height: upload.height, durationMs: upload.durationMs, thumbnailPath: thumbnailPath, sizeBytes: upload.bytes.length));
      }
      await ref.read(diaryRepositoryProvider).addMedia(widget.outingId, items);
      ref.invalidate(outingProvider(widget.outingId));
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    catch (_) {
      if (uploadedPaths.isNotEmpty) await ref.read(supabaseClientProvider).storage.from('diary-media').remove(uploadedPaths);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('diary.errors.media_upload'.tr())));
    } finally { if (mounted) setState(() => _uploading = false); }
  }

  Future<void> _delete(OutingMedia media) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('diary.media.delete_title'.tr()), content: Text('diary.media.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'diary.actions.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(diaryRepositoryProvider).removeMedia(media.id); ref.read(diaryMediaUrlServiceProvider).evict([media.path, if (media.thumbnailPath != null) media.thumbnailPath!]); ref.invalidate(outingProvider(widget.outingId)); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _caption(OutingMedia media) async {
    final controller = TextEditingController(text: media.caption);
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(title: Text('diary.media.caption'.tr()), content: HBInput(controller: controller, maxLength: 500), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: () => dialogContext.pop(controller.text.trim()))]));
    controller.dispose();
    if (value == null) return;
    await ref.read(diaryRepositoryProvider).updateMediaCaption(media.id, value.isEmpty ? null : value);
    ref.invalidate(outingProvider(widget.outingId));
  }

  @override
  Widget build(BuildContext context) => ref.watch(outingProvider(widget.outingId)).when(
    loading: () => const HBCard(child: LinearProgressIndicator()),
    error: (_, __) => const SizedBox.shrink(),
    data: (outing) {
      final media = outing?.media ?? const <OutingMedia>[];
      final paths = [for (final item in media) item.thumbnailPath ?? item.path];
      return FutureBuilder<Map<String, String>>(future: ref.read(diaryMediaUrlServiceProvider).createSignedUrls(paths), builder: (context, snapshot) {
        final urls = snapshot.data ?? const <String, String>{};
        return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('diary.photos'.tr(), style: context.textStyles.titleMedium)), if (widget.editable && media.length < 30) HBButton.secondary(label: 'diary.media.add'.tr(), icon: Icons.add_photo_alternate_outlined, onPressed: _uploading ? null : _upload)]),
          if (_uploading) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress)],
          const SizedBox(height: AppSpacing.md),
          if (media.isEmpty) HBEmptyState(icon: Icons.photo_library_outlined, title: 'diary.media.empty_title'.tr(), message: 'diary.media.empty_message'.tr()) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm), itemCount: media.length, itemBuilder: (_, index) {
            final item = media[index]; final url = urls[item.thumbnailPath ?? item.path];
            return GestureDetector(onTap: () async { final full = await ref.read(diaryMediaUrlServiceProvider).createSignedUrls(media.expand((item) => [item.path, item.thumbnailPath])); if (context.mounted) showDialog<void>(context: context, useSafeArea: false, builder: (_) => DiaryMediaViewer(items: media, urls: full, initialIndex: index)); }, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Stack(fit: StackFit.expand, children: [if (url == null) const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.image_outlined)) else Image.network(url, fit: BoxFit.cover), if (item.kind == 'video') const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 42)), if (widget.editable) Positioned(right: 4, top: 4, child: PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded, color: Colors.white), onSelected: (value) => value == 'delete' ? _delete(item) : _caption(item), itemBuilder: (_) => [PopupMenuItem(value: 'caption', child: Text('diary.media.caption'.tr())), PopupMenuItem(value: 'delete', child: Text('diary.actions.delete'.tr()))]))])));
          }),
        ]));
      });
    },
  );
}

class DiaryMediaViewer extends StatefulWidget {
  final List<OutingMedia> items;
  final Map<String, String> urls;
  final int initialIndex;
  const DiaryMediaViewer({super.key, required this.items, required this.urls, required this.initialIndex});
  @override
  State<DiaryMediaViewer> createState() => _DiaryMediaViewerState();
}
class _DiaryMediaViewerState extends State<DiaryMediaViewer> {
  late final PageController controller = PageController(initialPage: widget.initialIndex);
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(backgroundColor: Colors.black, child: Stack(children: [PageView.builder(controller: controller, itemCount: widget.items.length, itemBuilder: (_, index) { final item = widget.items[index]; final url = widget.urls[item.path]; if (url == null) return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white)); return item.kind == 'video' ? DiaryVideo(url: url) : InteractiveViewer(child: Center(child: Image.network(url, fit: BoxFit.contain))); }), Positioned(top: AppSpacing.lg, right: AppSpacing.lg, child: HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop()))]));
}

class DiaryVideo extends StatefulWidget {
  final String url;
  const DiaryVideo({super.key, required this.url});
  @override
  State<DiaryVideo> createState() => _DiaryVideoState();
}
class _DiaryVideoState extends State<DiaryVideo> {
  late final VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  @override
  void initState() { super.initState(); controller.initialize().then((_) { if (mounted) setState(() {}); }); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Center(child: controller.value.isInitialized ? GestureDetector(onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()), child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))) : const CircularProgressIndicator());
}