import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:image/image.dart' as img;

/// Interactive, in-memory image cropper shared by all media flows.
class HBImageCropper extends StatefulWidget {
  final Uint8List bytes;
  final double aspectRatio;
  final int outputWidth;
  final int outputHeight;
  final int jpegQuality;
  final bool circularMask;

  const HBImageCropper({super.key, required this.bytes, required this.aspectRatio, required this.outputWidth, required this.outputHeight, this.jpegQuality = 85, this.circularMask = false});

  static Future<Uint8List?> show(BuildContext context, {required Uint8List bytes, required double aspectRatio, required int outputWidth, required int outputHeight, int jpegQuality = 85, bool circularMask = false}) => showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(insetPadding: const EdgeInsets.all(AppSpacing.md), child: HBImageCropper(bytes: bytes, aspectRatio: aspectRatio, outputWidth: outputWidth, outputHeight: outputHeight, jpegQuality: jpegQuality, circularMask: circularMask)),
  );

  @override
  State<HBImageCropper> createState() => _HBImageCropperState();
}

class _HBImageCropperState extends State<HBImageCropper> {
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  late final img.Image _source;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final decoded = img.decodeImage(widget.bytes);
    if (decoded == null) throw const AppException('errors.image_processing_failed');
    _source = img.bakeOrientation(decoded);
  }

  @override
  void dispose() { _transform.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw const AppException('errors.image_processing_failed');
      final ratio = widget.outputWidth / boundary.size.width;
      final rendered = await boundary.toImage(pixelRatio: ratio);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      final decoded = data == null ? null : img.decodePng(data.buffer.asUint8List());
      if (decoded == null) throw const AppException('errors.image_processing_failed');
      final exact = decoded.width == widget.outputWidth && decoded.height == widget.outputHeight ? decoded : img.copyResize(decoded, width: widget.outputWidth, height: widget.outputHeight, interpolation: img.Interpolation.average);
      final result = Uint8List.fromList(img.encodeJpg(exact, quality: widget.jpegQuality));
      if (mounted) context.pop(result);
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('media_crop.title'.tr(), style: context.textStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text('media_crop.help'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        const SizedBox(height: AppSpacing.md),
        Flexible(child: Center(child: LayoutBuilder(builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          final width = (maxHeight * widget.aspectRatio).clamp(1.0, maxWidth);
          final height = width / widget.aspectRatio;
          final sourceRatio = _source.width / _source.height;
          final imageWidth = sourceRatio >= widget.aspectRatio ? height * sourceRatio : width;
          final imageHeight = sourceRatio >= widget.aspectRatio ? height : width / sourceRatio;
          final crop = RepaintBoundary(
            key: _captureKey,
            child: ClipRect(child: SizedBox(width: width, height: height, child: InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              alignment: Alignment.center,
              minScale: 1,
              maxScale: 6,
              boundaryMargin: EdgeInsets.zero,
              child: Image.memory(widget.bytes, width: imageWidth, height: imageHeight, fit: BoxFit.cover),
            ))),
          );
          return Stack(alignment: Alignment.center, children: [crop, IgnorePointer(child: Container(width: width, height: height, decoration: BoxDecoration(shape: widget.circularMask ? BoxShape.circle : BoxShape.rectangle, border: Border.all(color: Colors.white, width: 2))))]);
        }))),
        const SizedBox(height: AppSpacing.md),
        Row(children: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: _saving ? null : () => context.pop()), const Spacer(), HBButton.secondary(label: 'media_crop.reset'.tr(), onPressed: _saving ? null : () => _transform.value = Matrix4.identity()), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'media_crop.apply'.tr(), onPressed: _saving ? null : _save, isLoading: _saving)]),
      ]),
    ),
  );
}