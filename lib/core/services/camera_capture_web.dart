import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/camera_capture_result.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:web/web.dart' as web;

/// Opens the browser webcam and returns a single JPEG snapshot.
Future<CapturedMedia?> captureFromCamera(BuildContext context, {required bool video}) =>
    showDialog<CapturedMedia>(context: context, barrierDismissible: false, builder: (_) => const WebcamCaptureDialog());

/// Shows the live webcam preview with a shutter button, on web only.
class WebcamCaptureDialog extends StatefulWidget {
  const WebcamCaptureDialog({super.key});

  @override
  State<WebcamCaptureDialog> createState() => _WebcamCaptureDialogState();
}

class _WebcamCaptureDialogState extends State<WebcamCaptureDialog> {
  late final String _viewType = 'hb-webcam-${DateTime.now().microsecondsSinceEpoch}';
  late final web.HTMLVideoElement _video;
  web.MediaStream? _stream;
  bool _ready = false;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', '')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _video);
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final stream = await web.window.navigator.mediaDevices.getUserMedia(web.MediaStreamConstraints(video: true.toJS)).toDart;
      _stream = stream;
      _video.srcObject = stream;
      await _video.play().toDart;
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      debugPrint('[webcam] start failed: $error');
      if (mounted) setState(() => _errorKey = 'media_source.webcam_denied');
    }
  }

  void _stop() {
    final tracks = _stream?.getTracks().toDart ?? const <web.MediaStreamTrack>[];
    for (final track in tracks) {
      track.stop();
    }
    _stream = null;
    _video.srcObject = null;
  }

  void _capture() {
    final width = _video.videoWidth;
    final height = _video.videoHeight;
    if (width <= 0 || height <= 0) {
      setState(() => _errorKey = 'media_source.webcam_failed');
      return;
    }
    final canvas = web.HTMLCanvasElement()
      ..width = width
      ..height = height;
    final context2d = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    context2d.drawImage(_video, 0, 0);
    final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
    final bytes = UriData.parse(dataUrl).contentAsBytes();
    _stop();
    context.pop(CapturedMedia(bytes: bytes, name: 'webcam.jpg', extension: 'jpg', contentType: 'image/jpeg', isVideo: false));
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              color: Colors.black,
              child: _errorKey != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(_errorKey!.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))))
                  : Stack(fit: StackFit.expand, children: [HtmlElementView(viewType: _viewType), if (!_ready) const Center(child: CircularProgressIndicator())]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () { _stop(); context.pop(); }),
                HBButton.primary(label: 'media_source.take_photo'.tr(), onPressed: _ready && _errorKey == null ? _capture : null),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
