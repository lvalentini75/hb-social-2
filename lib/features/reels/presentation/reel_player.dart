import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:easy_localization/easy_localization.dart';

class ReelPlayer extends StatefulWidget {
  final String hls;
  final String? thumbnail;
  final double aspectRatio;
  final bool active;
  final VoidCallback onThreeSeconds;
  final VoidCallback onCompleted;
  final VoidCallback onDoubleTap;

  const ReelPlayer({super.key, required this.hls, this.thumbnail, required this.aspectRatio, required this.active, required this.onThreeSeconds, required this.onCompleted, required this.onDoubleTap});

  static bool sessionMuted = false;

  @override State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _viewRecorded = false;
  bool _completionRecorded = false;
  bool _failed = false;
  bool _reduceMotion = false;

  @override void initState() { super.initState(); _initialize(); }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.hls));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(ReelPlayer.sessionMuted ? 0 : 1);
      controller.addListener(_listen);
      if (widget.active && !_reduceMotion) await controller.play();
      if (mounted) setState(() {});
    } catch (_) { if (mounted) setState(() => _failed = true); }
  }

  @override void didChangeDependencies() { super.didChangeDependencies(); final value = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context); if (_reduceMotion != value) { _reduceMotion = value; if (value) _controller?.pause(); } }

  void _listen() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    if (!_ready && position > Duration.zero) setState(() => _ready = true);
    if (!_viewRecorded && position >= const Duration(seconds: 3)) { _viewRecorded = true; widget.onThreeSeconds(); }
    if (!_completionRecorded && controller.value.duration > Duration.zero && position >= controller.value.duration - const Duration(milliseconds: 250)) { _completionRecorded = true; widget.onCompleted(); }
    if (position < const Duration(milliseconds: 300)) _completionRecorded = false;
    setState(() {});
  }

  @override void didUpdateWidget(covariant ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hls != widget.hls) { _disposeController(); _ready = false; _viewRecorded = false; _completionRecorded = false; _failed = false; _initialize(); return; }
    final controller = _controller;
    if (controller?.value.isInitialized == true) widget.active && !_reduceMotion ? controller!.play() : controller!.pause();
  }

  Future<void> _disposeController() async { final controller = _controller; _controller = null; controller?.removeListener(_listen); await controller?.dispose(); }
  @override void dispose() { unawaited(_disposeController()); super.dispose(); }

  void _togglePlayback() { final controller = _controller; if (controller == null) return; controller.value.isPlaying ? controller.pause() : controller.play(); setState(() {}); }
  void _toggleMute() { ReelPlayer.sessionMuted = !ReelPlayer.sessionMuted; _controller?.setVolume(ReelPlayer.sessionMuted ? 0 : 1); setState(() {}); }

  @override Widget build(BuildContext context) {
    final controller = _controller;
    final progress = controller?.value.isInitialized == true && controller!.value.duration.inMilliseconds > 0 ? controller.value.position.inMilliseconds / controller.value.duration.inMilliseconds : 0.0;
    return GestureDetector(onTap: _togglePlayback, onDoubleTap: widget.onDoubleTap, child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      if (widget.thumbnail?.isNotEmpty == true) Image.network(widget.thumbnail!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
      if (_ready && controller?.value.isInitialized == true) Center(child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller))),
      if (!_ready && !_failed) const Center(child: CircularProgressIndicator(color: Colors.white)),
      if (_failed) const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 42)),
      if (controller?.value.isInitialized == true && !controller!.value.isPlaying) const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 72)),
      Positioned(top: 12, right: 12, child: IconButton(tooltip: 'a11y.toggle_audio'.tr(), onPressed: _toggleMute, icon: Icon(ReelPlayer.sessionMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white))),
      Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 2, color: Colors.white, backgroundColor: Colors.white24)),
    ]));
  }
}