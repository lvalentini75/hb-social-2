import 'dart:typed_data';

class VideoPosterResult {
  final Uint8List bytes;
  final int width;
  final int height;
  final int durationMs;

  const VideoPosterResult({required this.bytes, required this.width, required this.height, required this.durationMs});
}