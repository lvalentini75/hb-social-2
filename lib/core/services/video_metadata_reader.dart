import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/video_metadata_reader_stub.dart'
    if (dart.library.js_interop) 'package:hb_social/core/services/video_metadata_reader_web.dart' as platform;

/// Reads video metadata using the implementation provided by the current platform.
Future<Duration> readVideoDuration(PreparedUpload upload) => platform.readVideoDuration(upload);