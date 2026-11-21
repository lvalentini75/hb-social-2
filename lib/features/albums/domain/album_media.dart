enum AlbumMediaKind { image, video }

class AlbumMedia {
  final String id;
  final String albumId;
  final String ownerId;
  final String path;
  final AlbumMediaKind kind;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailPath;
  final int sizeBytes;
  final String? caption;
  final DateTime? takenAt;
  final int sortOrder;
  final DateTime createdAt;

  const AlbumMedia({required this.id, required this.albumId, required this.ownerId, required this.path, required this.kind, this.width, this.height, this.durationMs, this.thumbnailPath, required this.sizeBytes, this.caption, this.takenAt, required this.sortOrder, required this.createdAt});

  factory AlbumMedia.fromJson(Map<String, dynamic> json) => AlbumMedia(
    id: json['id'] as String? ?? '', albumId: json['album_id'] as String? ?? '', ownerId: json['owner_id'] as String? ?? '', path: json['path'] as String? ?? '',
    kind: json['kind'] == 'video' ? AlbumMediaKind.video : AlbumMediaKind.image,
    width: (json['width'] as num?)?.toInt(), height: (json['height'] as num?)?.toInt(), durationMs: (json['duration_ms'] as num?)?.toInt(), thumbnailPath: json['thumbnail_path'] as String?, sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    caption: json['caption'] as String?, takenAt: _date(json['taken_at']), sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0, createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  Map<String, dynamic> toRpcJson() => {'path': path, 'kind': kind.name, 'width': width, 'height': height, 'duration_ms': durationMs, 'thumbnail_path': thumbnailPath, 'size_bytes': sizeBytes, 'caption': caption, 'taken_at': takenAt?.toUtc().toIso8601String()};

  AlbumMedia copyWith({String? caption, DateTime? takenAt, bool clearCaption = false, bool clearTakenAt = false, int? sortOrder}) => AlbumMedia(
    id: id, albumId: albumId, ownerId: ownerId, path: path, kind: kind, width: width, height: height, durationMs: durationMs, thumbnailPath: thumbnailPath, sizeBytes: sizeBytes,
    caption: clearCaption ? null : caption ?? this.caption, takenAt: clearTakenAt ? null : takenAt ?? this.takenAt, sortOrder: sortOrder ?? this.sortOrder, createdAt: createdAt,
  );
}

DateTime? _date(Object? value) => value is DateTime ? value : value is String ? DateTime.tryParse(value) : null;