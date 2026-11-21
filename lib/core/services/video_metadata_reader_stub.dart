import 'dart:io';

import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<Duration> readVideoDuration(PreparedUpload upload) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/hb_story_${DateTime.now().microsecondsSinceEpoch}.${upload.extension}');
  await file.writeAsBytes(upload.bytes, flush: true);
  final controller = VideoPlayerController.file(file);
  try {
    await controller.initialize().timeout(const Duration(seconds: 8));
    final duration = controller.value.duration;
    if (duration <= Duration.zero) throw const AppException('errors.video_unreadable');
    return duration;
  } on AppException {
    rethrow;
  } catch (_) {
    throw const AppException('errors.video_unreadable');
  } finally {
    await controller.dispose();
    if (await file.exists()) await file.delete();
  }
}