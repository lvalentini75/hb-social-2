import 'package:flutter/widgets.dart';
import 'package:hb_social/core/services/camera_capture_result.dart';
import 'package:image_picker/image_picker.dart';

/// Opens the native camera for a single photo or a short video.
Future<CapturedMedia?> captureFromCamera(BuildContext context, {required bool video}) async {
  final picker = ImagePicker();
  final file = video ? await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 2)) : await picker.pickImage(source: ImageSource.camera);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.name.isEmpty ? (video ? 'camera.mp4' : 'camera.jpg') : file.name;
  final extension = name.contains('.') ? name.split('.').last.toLowerCase() : (video ? 'mp4' : 'jpg');
  final contentType = video ? (extension == 'mov' ? 'video/quicktime' : 'video/mp4') : (extension == 'png' ? 'image/png' : 'image/jpeg');
  return CapturedMedia(bytes: bytes, name: name, extension: extension, contentType: contentType, isVideo: video);
}
