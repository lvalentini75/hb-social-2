import 'dart:typed_data';

/// One photo or video captured live from a device camera or a browser webcam.
class CapturedMedia {
  final Uint8List bytes;
  final String name;
  final String extension;
  final String contentType;
  final bool isVideo;

  const CapturedMedia({required this.bytes, required this.name, required this.extension, required this.contentType, required this.isVideo});
}
