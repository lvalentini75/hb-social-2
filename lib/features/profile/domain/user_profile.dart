/// A public profile backed by `user_profiles`.
class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String countryCode;
  final String? homeRegionId;
  final String? huntingUnitId;
  final String? homeMunicipalityId;
  final String locale;
  final String currencyCode;
  final String unitSystem;
  final String status;
  final String verificationLevel;
  final DateTime? verifiedAt;
  final DateTime? verificationExpiresAt;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int outingsCount;
  final int friendCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? ageConfirmedAt;
  final DateTime? lastSeenAt;
  final DateTime? suspendedUntil;
  final int sellerRatingAverageHundredths;
  final int sellerRatingCount;

  bool get isVerified => verificationLevel != 'none';

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    required this.countryCode,
    this.homeRegionId,
    this.huntingUnitId,
    this.homeMunicipalityId,
    required this.locale,
    required this.currencyCode,
    required this.unitSystem,
    required this.status,
    required this.verificationLevel,
    this.verifiedAt,
    this.verificationExpiresAt,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.outingsCount = 0,
    this.friendCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.ageConfirmedAt,
    this.lastSeenAt,
    this.suspendedUntil,
    this.sellerRatingAverageHundredths = 0,
    this.sellerRatingCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String? ?? '',
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    countryCode: json['country_code'] as String? ?? 'IT',
    homeRegionId: json['home_region_id'] as String?,
    huntingUnitId: json['hunting_unit_id'] as String?,
    homeMunicipalityId: json['home_municipality_id'] as String?,
    locale: json['locale'] as String? ?? 'en',
    currencyCode: json['currency_code'] as String? ?? 'EUR',
    unitSystem: json['unit_system'] as String? ?? 'metric',
    status: json['status'] as String? ?? 'active',
    verificationLevel: json['verification_level'] as String? ?? 'none',
    verifiedAt: _dateTime(json['verified_at']),
    verificationExpiresAt: _dateTime(json['verification_expires_at']),
    followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
    followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
    postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    outingsCount: (json['outing_count'] as num?)?.toInt() ?? 0,
    friendCount: (json['friend_count'] as num?)?.toInt() ?? 0,
    createdAt: _dateTime(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: _dateTime(json['updated_at']),
    ageConfirmedAt: _dateTime(json['age_confirmed_at']),
    lastSeenAt: _dateTime(json['last_seen_at']),
    suspendedUntil: _dateTime(json['suspended_until']),
    sellerRatingAverageHundredths: _ratingHundredths(json['seller_rating_avg']),
    sellerRatingCount: (json['seller_rating_count'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'country_code': countryCode,
    'home_region_id': homeRegionId,
    'hunting_unit_id': huntingUnitId,
    'home_municipality_id': homeMunicipalityId,
    'locale': locale,
    'currency_code': currencyCode,
    'unit_system': unitSystem,
    'status': status,
    'verification_level': verificationLevel,
    'verified_at': verifiedAt?.toIso8601String(),
    'verification_expires_at': verificationExpiresAt?.toIso8601String(),
    'follower_count': followerCount,
    'following_count': followingCount,
    'post_count': postCount,
    'outing_count': outingsCount,
    'friend_count': friendCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'age_confirmed_at': ageConfirmedAt?.toIso8601String(),
    'last_seen_at': lastSeenAt?.toIso8601String(),
    'suspended_until': suspendedUntil?.toIso8601String(),
    'seller_rating_avg': sellerRatingAverageHundredths,
    'seller_rating_count': sellerRatingCount,
  };

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? countryCode,
    String? homeRegionId,
    String? huntingUnitId,
    String? homeMunicipalityId,
    String? locale,
    String? currencyCode,
    String? unitSystem,
    String? status,
    String? verificationLevel,
    DateTime? verifiedAt,
    DateTime? verificationExpiresAt,
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? outingsCount,
    int? friendCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? ageConfirmedAt,
    DateTime? lastSeenAt,
    DateTime? suspendedUntil,
    int? sellerRatingAverageHundredths,
    int? sellerRatingCount,
  }) => UserProfile(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    countryCode: countryCode ?? this.countryCode,
    homeRegionId: homeRegionId ?? this.homeRegionId,
    huntingUnitId: huntingUnitId ?? this.huntingUnitId,
    homeMunicipalityId: homeMunicipalityId ?? this.homeMunicipalityId,
    locale: locale ?? this.locale,
    currencyCode: currencyCode ?? this.currencyCode,
    unitSystem: unitSystem ?? this.unitSystem,
    status: status ?? this.status,
    verificationLevel: verificationLevel ?? this.verificationLevel,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    verificationExpiresAt: verificationExpiresAt ?? this.verificationExpiresAt,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount ?? this.followingCount,
    postCount: postCount ?? this.postCount,
    outingsCount: outingsCount ?? this.outingsCount,
    friendCount: friendCount ?? this.friendCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    ageConfirmedAt: ageConfirmedAt ?? this.ageConfirmedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    suspendedUntil: suspendedUntil ?? this.suspendedUntil,
    sellerRatingAverageHundredths: sellerRatingAverageHundredths ?? this.sellerRatingAverageHundredths,
    sellerRatingCount: sellerRatingCount ?? this.sellerRatingCount,
  );
}

int _ratingHundredths(Object? value) { if (value is int) return value > 5 ? value : value * 100; if (value is num) return (value * 100).round(); return 0; }

DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}
