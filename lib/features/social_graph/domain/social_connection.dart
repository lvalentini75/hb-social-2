class SocialProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final DateTime? verifiedAt;
  final DateTime? lastSeenAt;

  const SocialProfile({required this.id, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, this.verifiedAt, this.lastSeenAt});

  factory SocialProfile.fromJson(Map<String, dynamic> json) => SocialProfile(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    verificationLevel: json['verification_level'] as String? ?? 'none',
    verifiedAt: json['verified_at'] == null ? null : DateTime.tryParse(json['verified_at'].toString())?.toUtc(),
    lastSeenAt: json['last_seen_at'] == null ? null : DateTime.tryParse(json['last_seen_at'] as String)?.toUtc(),
  );

  bool get isVerified => verificationLevel != 'none';
}

class SocialConnection {
  final String id;
  final DateTime createdAt;
  final SocialProfile profile;
  final bool isFriend;

  const SocialConnection({required this.id, required this.createdAt, required this.profile, this.isFriend = false});
}

class FriendProfile {
  final SocialProfile profile;
  final DateTime friendsSince;
  final bool mutual;

  const FriendProfile({required this.profile, required this.friendsSince, required this.mutual});

  factory FriendProfile.fromJson(Map<String, dynamic> json) => FriendProfile(
    profile: SocialProfile.fromJson(json),
    friendsSince: DateTime.parse(json['friends_since'] as String).toUtc(),
    mutual: json['mutual'] as bool? ?? false,
  );
}

class RelationshipStatus {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isFriend;
  final String? outgoingRequestId;
  final String? incomingRequestId;
  final bool blockedByMe;
  final bool blockedMe;
  final bool mutedByMe;

  const RelationshipStatus({required this.isFollowing, required this.isFollowedBy, required this.isFriend, this.outgoingRequestId, this.incomingRequestId, required this.blockedByMe, required this.blockedMe, required this.mutedByMe});

  factory RelationshipStatus.fromJson(Map<String, dynamic> json) => RelationshipStatus(
    isFollowing: json['is_following'] as bool? ?? false,
    isFollowedBy: json['is_followed_by'] as bool? ?? false,
    isFriend: json['is_friend'] as bool? ?? false,
    outgoingRequestId: json['outgoing_request_id'] as String?,
    incomingRequestId: json['incoming_request_id'] as String?,
    blockedByMe: json['blocked_by_me'] as bool? ?? false,
    blockedMe: json['blocked_me'] as bool? ?? false,
    mutedByMe: json['muted_by_me'] as bool? ?? false,
  );
}

class FriendRequest {
  final String id;
  final String? message;
  final DateTime createdAt;
  final SocialProfile profile;

  const FriendRequest({required this.id, this.message, required this.createdAt, required this.profile});
}