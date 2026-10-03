/// A public user profile, mirroring the future `profiles` table (see
/// ARCHITECTURE.md). Handwritten `fromJson`/`toJson`/`copyWith` per AGENTS
/// rule 9 (no code generation).
class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int outingsCount;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.outingsCount = 0,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
    followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
    postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    outingsCount: (json['outings_count'] as num?)?.toInt() ?? 0,
    isVerified: json['is_verified'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'follower_count': followerCount,
    'following_count': followingCount,
    'post_count': postCount,
    'outings_count': outingsCount,
    'is_verified': isVerified,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? outingsCount,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount ?? this.followingCount,
    postCount: postCount ?? this.postCount,
    outingsCount: outingsCount ?? this.outingsCount,
    isVerified: isVerified ?? this.isVerified,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
