import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/albums/domain/album.dart';
import 'package:hb_social/features/albums/domain/album_media.dart';
import 'package:hb_social/features/albums/presentation/album_media_edit_sheet.dart';
import 'package:hb_social/features/albums/presentation/album_cover_action.dart';
import 'package:hb_social/features/albums/providers/album_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_video.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AlbumViewerPage extends ConsumerStatefulWidget {
  final String albumId;
  final String mediaId;
  const AlbumViewerPage({super.key, required this.albumId, required this.mediaId});
  @override
  ConsumerState<AlbumViewerPage> createState() => _AlbumViewerPageState();
}

class _AlbumViewerPageState extends ConsumerState<AlbumViewerPage> {
  PageController? _pages;
  final ValueNotifier<int> _videoToggle = ValueNotifier(0);
  int _index = 0;
  bool _barsVisible = true;
  bool _zoomed = false;
  double _verticalDrag = 0;

  @override
  void dispose() { _pages?.dispose(); _videoToggle.dispose(); super.dispose(); }

  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.albumDetailPath(widget.albumId));

  KeyEventResult _key(KeyEvent event, int length) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) { _close(); return KeyEventResult.handled; }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _index > 0) { _pages?.previousPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut); return KeyEventResult.handled; }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight && _index < length - 1) { _pages?.nextPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut); return KeyEventResult.handled; }
    if (event.logicalKey == LogicalKeyboardKey.space) { _videoToggle.value++; return KeyEventResult.handled; }
    return KeyEventResult.ignored;
  }

  Future<void> _edit(AlbumMedia media) async {
    final result = await showAlbumMediaEditSheet(context, media);
    if (result == null) return;
    try { await ref.read(albumMediaProvider(widget.albumId).notifier).updateMedia(media, caption: result.caption, takenAt: result.takenAt); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _delete(AlbumMedia media) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('albums_p23b.delete_media_title'.tr()), content: Text('albums_p23b.delete_media_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'albums_p23b.delete_action'.tr(), foregroundColor: LightModeColors.lightError, onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try {
      await ref.read(albumMediaProvider(widget.albumId).notifier).remove(media);
      final remaining = ref.read(albumMediaProvider(widget.albumId)).value?.items.length ?? 0;
      if (remaining == 0) _close(); else if (_index >= remaining) setState(() => _index = remaining - 1);
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _action(String action, Album album, AlbumMedia media, String url, bool isOwner) async {
    if (action == 'download') { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: kIsWeb ? '_blank' : null); return; }
    if (action == 'cover') { try { await AlbumCoverAction.run(context, ref, album, media); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } return; }
    if (action == 'edit') { await _edit(media); return; }
    if (action == 'delete') { await _delete(media); return; }
    if (!isOwner && action == 'report') {
      if (ref.read(authSessionProvider).value == null) { if (mounted) context.push(AppRoutes.login); return; }
      if (mounted && await showReportSheet(context, targetType: 'album', targetId: album.id, titleKey: 'albums.report_title') && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.report_success'.tr())));
    }
  }

  void _precache(List<AlbumMedia> items, Map<String, String> urls) {
    for (final index in [_index - 1, _index + 1]) {
      if (index < 0 || index >= items.length || items[index].kind != AlbumMediaKind.image) continue;
      final url = urls[items[index].path];
      if (url != null) precacheImage(NetworkImage(url), context);
    }
  }

  @override
  Widget build(BuildContext context) => ref.watch(albumProvider(widget.albumId)).when(
    loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white))),
    error: (_, __) => const AlbumViewerUnavailable(),
    data: (album) {
      if (album == null) return const AlbumViewerUnavailable();
      final isOwner = ref.watch(authSessionProvider).value?.user.id == album.ownerId;
      return ref.watch(albumMediaProvider(album.id)).when(
        loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (_, __) => const AlbumViewerUnavailable(),
        data: (state) {
          var target = state.items.indexWhere((item) => item.id == widget.mediaId);
          if (target < 0 && state.hasMore) { WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(albumMediaProvider(album.id).notifier).loadMore()); return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white))); }
          if (target < 0 || state.items.isEmpty) return const AlbumViewerUnavailable();
          _pages ??= PageController(initialPage: target);
          if (_pages?.hasClients != true) _index = target;
          final paths = state.items.expand((item) => [item.path, if (item.thumbnailPath != null) item.thumbnailPath!]).toList();
          return FutureBuilder<Map<String, String>>(
            future: ref.read(albumMediaUrlServiceProvider).signedUrls(paths),
            builder: (context, snapshot) {
              final urls = snapshot.data ?? const <String, String>{};
              if (snapshot.hasData) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _precache(state.items, urls); });
              return Focus(
                autofocus: true,
                onKeyEvent: (_, event) => _key(event, state.items.length),
                child: Scaffold(
                  backgroundColor: Colors.black,
                  body: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _barsVisible = !_barsVisible),
                    onVerticalDragUpdate: kIsWeb ? null : (details) => _verticalDrag += details.delta.dy,
                    onVerticalDragEnd: kIsWeb ? null : (_) { if (_verticalDrag > 100) _close(); _verticalDrag = 0; },
                    child: Stack(children: [
                      PageView.builder(
                        controller: _pages,
                        physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                        itemCount: state.items.length,
                        onPageChanged: (index) {
                          setState(() { _index = index; _zoomed = false; });
                          if (index >= state.items.length - 3) ref.read(albumMediaProvider(album.id).notifier).loadMore();
                        },
                        itemBuilder: (_, index) {
                          final media = state.items[index];
                          final url = urls[media.path];
                          if (url == null) return const Center(child: CircularProgressIndicator(color: Colors.white));
                          if (media.kind == AlbumMediaKind.video) {
                            final postMedia = PostMedia(id: media.id, url: url, kind: 'video', sortOrder: media.sortOrder, width: media.width, height: media.height, durationMs: media.durationMs, thumbnailUrl: media.thumbnailPath == null ? null : urls[media.thumbnailPath]);
                            return Center(child: PostVideo(key: ValueKey(media.id), media: postMedia, active: index == _index, startMuted: false, toggleSignal: _videoToggle));
                          }
                          return AlbumZoomImage(url: url, active: index == _index, onZoomChanged: (zoomed) { if (index == _index && zoomed != _zoomed) setState(() => _zoomed = zoomed); });
                        },
                      ),
                      if (_barsVisible) AlbumViewerTopBar(index: _index, total: album.itemCount, isOwner: isOwner, onClose: _close, onAction: (action) => _action(action, album, state.items[_index], urls[state.items[_index].path] ?? '', isOwner)),
                      if (_barsVisible) AlbumViewerCaption(album: album, media: state.items[_index]),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

class AlbumZoomImage extends StatefulWidget {
  final String url;
  final bool active;
  final ValueChanged<bool> onZoomChanged;
  const AlbumZoomImage({super.key, required this.url, required this.active, required this.onZoomChanged});
  @override
  State<AlbumZoomImage> createState() => _AlbumZoomImageState();
}

class _AlbumZoomImageState extends State<AlbumZoomImage> {
  final TransformationController _transform = TransformationController();
  TapDownDetails? _doubleTap;
  @override
  void dispose() { _transform.dispose(); super.dispose(); }
  void _toggleZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed) { _transform.value = Matrix4.identity(); widget.onZoomChanged(false); return; }
    final position = _doubleTap?.localPosition ?? Offset.zero;
    _transform.value = Matrix4.identity()..translate(-position.dx * 1.5, -position.dy * 1.5)..scale(2.5);
    widget.onZoomChanged(true);
  }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTapDown: (details) => _doubleTap = details,
    onDoubleTap: _toggleZoom,
    child: InteractiveViewer(transformationController: _transform, minScale: 1, maxScale: 5, onInteractionEnd: (_) => widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01), child: Center(child: Image.network(widget.url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white)))),
  );
}

class AlbumViewerTopBar extends StatelessWidget {
  final int index;
  final int total;
  final bool isOwner;
  final VoidCallback onClose;
  final ValueChanged<String> onAction;
  const AlbumViewerTopBar({super.key, required this.index, required this.total, required this.isOwner, required this.onClose, required this.onAction});
  @override
  Widget build(BuildContext context) => Positioned(left: 0, right: 0, top: 0, child: ColoredBox(color: Colors.black54, child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Row(children: [IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: Colors.white)), Expanded(child: Text('${index + 1} / $total', textAlign: TextAlign.center, style: context.textStyles.titleMedium?.copyWith(color: Colors.white))), PopupMenuButton<String>(iconColor: Colors.white, onSelected: onAction, itemBuilder: (_) => [PopupMenuItem(value: 'download', child: Text('albums_p23b.download'.tr())), if (isOwner) ...[PopupMenuItem(value: 'cover', child: Text('albums.set_cover'.tr())), PopupMenuItem(value: 'edit', child: Text('albums_p23b.edit_caption'.tr())), PopupMenuItem(value: 'delete', child: Text('albums_p23b.delete_action'.tr()))] else PopupMenuItem(value: 'report', child: Text('albums.report'.tr()))])])))));
}

class AlbumViewerCaption extends StatefulWidget {
  final Album album;
  final AlbumMedia media;
  const AlbumViewerCaption({super.key, required this.album, required this.media});
  @override
  State<AlbumViewerCaption> createState() => _AlbumViewerCaptionState();
}

class _AlbumViewerCaptionState extends State<AlbumViewerCaption> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final date = media.takenAt == null ? 'albums_p23b.added_time'.tr(namedArgs: {'time': relativeTime(context, media.createdAt)}) : DateFormat.yMMMd(context.locale.toString()).add_Hm().format(media.takenAt!.toLocal());
    return Positioned(left: 0, right: 0, bottom: 0, child: ColoredBox(color: Colors.black54, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (media.caption?.isNotEmpty == true) InkWell(onTap: () => setState(() => expanded = !expanded), child: Text(media.caption!, maxLines: expanded ? null : 3, overflow: expanded ? null : TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white))),
      if (media.caption?.isNotEmpty == true && !expanded) Text('albums_p23b.more'.tr(), style: context.textStyles.bodySmall?.copyWith(color: Colors.white70)),
      const SizedBox(height: AppSpacing.xs),
      Text(date, style: context.textStyles.bodySmall?.copyWith(color: Colors.white70)),
      Text(widget.album.owner?.displayName ?? '', style: context.textStyles.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    ])))));
  }
}

class AlbumViewerUnavailable extends StatelessWidget {
  const AlbumViewerUnavailable({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, body: Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_library_outlined, color: Colors.white, size: 52), const SizedBox(height: AppSpacing.md), Text('albums.unavailable_title'.tr(), style: context.textStyles.titleLarge?.copyWith(color: Colors.white)), const SizedBox(height: AppSpacing.sm), Text('albums.unavailable_message'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white70)), const SizedBox(height: AppSpacing.lg), HBButton.secondary(label: 'albums_p23b.close'.tr(), onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home))]))));
}