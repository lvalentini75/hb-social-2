/// A community/business page (named `CommunityPage` to avoid clashing with
/// Flutter's own `Page` class), mirroring the future `pages` table (see
/// ARCHITECTURE.md). Handwritten `fromJson`/`toJson`/`copyWith` per AGENTS
/// rule 9 (no code generation).
class CommunityPage {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final int followerCount;
  final bool isFollowing;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommunityPage({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    this.followerCount = 0,
    this.isFollowing = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityPage.fromJson(Map<String, dynamic> json) => CommunityPage(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
    isFollowing: json['is_following'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'follower_count': followerCount,
    'is_following': isFollowing,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  CommunityPage copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    int? followerCount,
    bool? isFollowing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CommunityPage(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    followerCount: followerCount ?? this.followerCount,
    isFollowing: isFollowing ?? this.isFollowing,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
