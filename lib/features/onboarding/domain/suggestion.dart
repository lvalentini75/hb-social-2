class SuggestedProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final DateTime? verifiedAt;
  final int followerCount;
  final int sharedInterests;
  final bool sameRegion;
  final int mutualFriends;
  final DateTime? lastSeenAt;

  const SuggestedProfile({required this.id, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, this.verifiedAt, required this.followerCount, required this.sharedInterests, required this.sameRegion, this.mutualFriends = 0, this.lastSeenAt});

  factory SuggestedProfile.fromJson(Map<String, dynamic> json) => SuggestedProfile(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    verificationLevel: json['verification_level'] as String? ?? 'none',
    verifiedAt: json['verified_at'] == null ? null : DateTime.tryParse(json['verified_at'].toString())?.toUtc(),
    followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
    sharedInterests: (json['shared_interests'] as num?)?.toInt() ?? 0,
    sameRegion: json['same_region'] as bool? ?? false,
    mutualFriends: (json['mutual_friends'] as num?)?.toInt() ?? 0,
    lastSeenAt: json['last_seen_at'] == null ? null : DateTime.tryParse(json['last_seen_at'] as String)?.toUtc(),
  );
}

class SuggestedGroup {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;
  final String? category;
  final int memberCount;
  final String? regionId;
  final bool matchesInterest;
  final bool sameRegion;

  const SuggestedGroup({required this.id, required this.slug, required this.name, this.avatarUrl, this.category, required this.memberCount, this.regionId, required this.matchesInterest, required this.sameRegion});

  factory SuggestedGroup.fromJson(Map<String, dynamic> json) => SuggestedGroup(
    id: json['id'] as String,
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    category: json['category'] as String?,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    regionId: json['region_id'] as String?,
    matchesInterest: json['matches_interest'] as bool? ?? false,
    sameRegion: json['same_region'] as bool? ?? false,
  );
}