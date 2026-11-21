import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForumAttachment {
  final String id;
  final String path;
  final String kind;
  final String mimeType;
  final int sizeBytes;
  final String fileName;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailPath;
  final int sortOrder;

  const ForumAttachment({required this.id, required this.path, required this.kind, required this.mimeType, required this.sizeBytes, required this.fileName, this.width, this.height, this.durationMs, this.thumbnailPath, required this.sortOrder});

  factory ForumAttachment.fromJson(Map<String, dynamic> json) => ForumAttachment(
    id: json['id'] as String,
    path: json['path'] as String,
    kind: json['kind'] as String,
    mimeType: json['mime_type'] as String? ?? '',
    sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    fileName: json['file_name'] as String? ?? '',
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    durationMs: (json['duration_ms'] as num?)?.toInt(),
    thumbnailPath: json['thumbnail_path'] as String?,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );

  PostMedia toPostMedia(SupabaseClient client) => PostMedia(id: id, url: storagePublicUrl(client, 'forum-media', path) ?? '', kind: kind, sortOrder: sortOrder, width: width, height: height, durationMs: durationMs, thumbnailPath: thumbnailPath, thumbnailUrl: storagePublicUrl(client, 'forum-media', thumbnailPath));
}