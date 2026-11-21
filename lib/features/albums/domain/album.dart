import 'package:hb_social/features/albums/domain/album_media.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

enum AlbumVisibility { public, friends, private }

class Album {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final AlbumVisibility visibility;
  final String? coverMediaId;
  final String? coverPath;
  final AlbumMedia? cover;
  final int itemCount;
  final String countryCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? owner;

  const Album({required this.id, required this.ownerId, required this.title, this.description, required this.visibility, this.coverMediaId, this.coverPath, this.cover, required this.itemCount, required this.countryCode, required this.createdAt, required this.updatedAt, this.owner});

  factory Album.fromJson(Map<String, dynamic> json) {
    final coverJson = json['cover'];
    final ownerJson = json['owner'];
    return Album(
      id: json['id'] as String? ?? '', ownerId: json['owner_id'] as String? ?? '', title: json['title'] as String? ?? '', description: json['description'] as String?,
      visibility: AlbumVisibility.values.where((value) => value.name == json['visibility']).firstOrNull ?? AlbumVisibility.public,
      coverMediaId: json['cover_media_id'] as String?, coverPath: json['cover_path'] as String?, cover: coverJson is Map ? AlbumMedia.fromJson({...Map<String, dynamic>.from(coverJson), 'album_id': json['id'], 'owner_id': json['owner_id']}) : null,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0, countryCode: json['country_code'] as String? ?? '', createdAt: _date(json['created_at']), updatedAt: _date(json['updated_at']),
      owner: ownerJson is Map ? UserProfile.fromJson({...Map<String, dynamic>.from(ownerJson), 'country_code': json['country_code'], 'created_at': json['created_at']}) : null,
    );
  }

  Album copyWith({String? title, String? description, AlbumVisibility? visibility, String? coverMediaId, String? coverPath, AlbumMedia? cover, int? itemCount, DateTime? updatedAt}) => Album(id: id, ownerId: ownerId, title: title ?? this.title, description: description ?? this.description, visibility: visibility ?? this.visibility, coverMediaId: coverMediaId ?? this.coverMediaId, coverPath: coverPath ?? this.coverPath, cover: cover ?? this.cover, itemCount: itemCount ?? this.itemCount, countryCode: countryCode, createdAt: createdAt, updatedAt: updatedAt ?? this.updatedAt, owner: owner);
}

DateTime _date(Object? value) => (value is DateTime ? value : value is String ? DateTime.tryParse(value) : null) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);