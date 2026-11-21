import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostVideo extends StatefulWidget {
  final PostMedia media;
  final bool showControls;
  final bool active;
  final bool startMuted;
  final ValueListenable<int>? toggleSignal;

  const PostVideo({super.key, required this.media, this.showControls = true, this.active = true, this.startMuted = true, this.toggleSignal});

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  static VideoPlayerController? _activePlayer;
  static final List<_PostVideoState> _previewOwners = [];
  VideoPlayerController? _controller;
  Timer? _visibilityTimer;
  bool _failed = false;
  bool _previewReady = false;
  bool _videoReady = false;
  bool _starting = false;

  bool get _hasPoster => widget.media.thumbnailUrl?.isNotEmpty == true;

  @override
  void initState() { super.initState(); widget.toggleSignal?.addListener(_toggleFromSignal); }

  @override
  void didUpdateWidget(covariant PostVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toggleSignal != widget.toggleSignal) { oldWidget.toggleSignal?.removeListener(_toggleFromSignal); widget.toggleSignal?.addListener(_toggleFromSignal); }
    if (!widget.active && oldWidget.active) _controller?.pause();
  }

  void _toggleFromSignal() { if (widget.active) _play(); }

  Future<void> _play() async {
    if (!widget.active) return;
    final controller = _controller;
    if (controller?.value.isPlaying == true) {
      await controller!.pause();
      if (mounted) setState(() {});
      return;
    }
    if (widget.media.url.isEmpty || _starting) return;
    setState(() => _starting = true);
    try {
      final next = controller ?? VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
      _controller = next;
      if (!next.value.isInitialized) await next.initialize();
      if (_activePlayer != next) await _activePlayer?.pause();
      _activePlayer = next;
      _previewOwners.remove(this);
      if (controller == null) await next.setVolume(widget.startMuted ? 0 : 1);
      next.addListener(_onVideoFrame);
      await next.play();
      if (_previewReady) _videoReady = true;
      if (mounted) setState(() => _starting = false);
    } catch (_) {
      if (mounted) setState(() { _failed = true; _starting = false; });
    }
  }

  void _onVideoFrame() {
    final controller = _controller;
    if (!mounted || _videoReady || controller == null || controller.value.position <= Duration.zero) return;
    setState(() => _videoReady = true);
  }

  void _scheduleLegacyPreview(double visibleFraction) {
    if (_hasPoster || _previewReady || _starting || _failed) return;
    if (visibleFraction <= 0) {
      _visibilityTimer?.cancel();
      _visibilityTimer = null;
      unawaited(_releasePreview());
      return;
    }
    _visibilityTimer ??= Timer(const Duration(milliseconds: 300), _initializeLegacyPreview);
  }

  Future<void> _initializeLegacyPreview() async {
    _visibilityTimer = null;
    if (!mounted || _previewReady || _starting) return;
    _previewOwners.remove(this);
    while (_previewOwners.length >= 2) await _previewOwners.removeAt(0)._releasePreview();
    _previewOwners.add(this);
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
      _controller = controller;
      await controller.initialize();
      await controller.setVolume(0);
      final target = controller.value.duration < const Duration(milliseconds: 300) ? Duration.zero : const Duration(milliseconds: 300);
      await controller.seekTo(target);
      await controller.pause();
      if (mounted) setState(() => _previewReady = true);
    } catch (_) {
      _previewOwners.remove(this);
      await _controller?.dispose();
      _controller = null;
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _releasePreview() async {
    if (!_previewOwners.remove(this) || _activePlayer == _controller) return;
    final controller = _controller;
    _controller = null;
    _previewReady = false;
    await controller?.dispose();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.toggleSignal?.removeListener(_toggleFromSignal);
    _visibilityTimer?.cancel();
    _previewOwners.remove(this);
    if (_activePlayer == _controller) _activePlayer = null;
    _controller?.removeListener(_onVideoFrame);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  String _duration() {
    final milliseconds = widget.media.durationMs ?? _controller?.value.duration.inMilliseconds;
    if (milliseconds == null || milliseconds <= 0) return '';
    final duration = Duration(milliseconds: milliseconds);
    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rawAspect = widget.media.width != null && widget.media.height != null && widget.media.height! > 0 ? widget.media.width! / widget.media.height! : 16 / 9;
    final aspect = rawAspect.clamp(4 / 5, 16 / 9).toDouble();
    final showVideo = (_previewReady || _videoReady) && _controller?.value.isInitialized == true;
    return VisibilityDetector(
      key: ValueKey('video-${widget.media.id}'),
      onVisibilityChanged: (info) {
        _scheduleLegacyPreview(info.visibleFraction);
        if (info.visibleFraction <= 0) _controller?.pause();
      },
      child: AspectRatio(
        aspectRatio: aspect,
        child: ColoredBox(
          color: LightModeColors.lightBackgroundSoft,
          child: Stack(fit: StackFit.expand, children: [
            if (_hasPoster) Image.network(widget.media.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const VideoPlaceholder()) else const VideoPlaceholder(),
            if (showVideo) VideoPlayer(_controller!),
            if (_failed) Center(child: Text('feed.video_unavailable'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
            if (!_failed && widget.showControls) ...[
              const VideoBottomOverlay(),
              Center(child: GestureDetector(
                onTap: _play,
                child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: LightModeColors.lightSurface, shape: BoxShape.circle, boxShadow: AppShadows.level2), child: Icon((_controller?.value.isPlaying ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded, color: LightModeColors.lightForest, size: 32)),
              )),
              const Positioned(left: AppSpacing.sm, bottom: AppSpacing.sm, child: Icon(Icons.videocam_rounded, color: Colors.white, size: 20)),
              if (_duration().isNotEmpty) Positioned(right: AppSpacing.sm, bottom: AppSpacing.sm, child: Text(_duration(), style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
              if (_controller?.value.isInitialized == true) ...[
                Positioned(left: AppSpacing.sm, right: AppSpacing.sm, bottom: 30, child: VideoProgressIndicator(_controller!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white54, backgroundColor: Colors.white24))),
                Positioned(left: AppSpacing.sm, top: AppSpacing.sm, child: IconButton(onPressed: () async { final muted = _controller!.value.volume == 0; await _controller!.setVolume(muted ? 1 : 0); if (mounted) setState(() {}); }, color: Colors.white, icon: Icon(_controller!.value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded))),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}

class VideoPlaceholder extends StatelessWidget {
  const VideoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.videocam_outlined, color: LightModeColors.lightTextTertiary, size: 34),
    const SizedBox(height: AppSpacing.xs),
    Text('media.video'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
  ])));
}

class VideoBottomOverlay extends StatelessWidget {
  const VideoBottomOverlay({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54], stops: [0.55, 1])));
}