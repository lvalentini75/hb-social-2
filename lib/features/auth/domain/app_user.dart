/// The authenticated user of the app. Until Supabase is connected this is
/// populated locally from the signup and onboarding flows — there is no
/// mocked or sample user data.
class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String bio;
  final String? avatarPath;
  final String? coverPath;
  final String? countryCode;
  final String? regionCode;
  final List<String> interestIds;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.bio = '',
    this.avatarPath,
    this.coverPath,
    this.countryCode,
    this.regionCode,
    this.interestIds = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? name,
    String? username,
    String? email,
    String? bio,
    String? avatarPath,
    String? coverPath,
    String? countryCode,
    String? regionCode,
    List<String>? interestIds,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
      countryCode: countryCode ?? this.countryCode,
      regionCode: regionCode ?? this.regionCode,
      interestIds: interestIds ?? this.interestIds,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'bio': bio,
        'avatarPath': avatarPath,
        'coverPath': coverPath,
        'countryCode': countryCode,
        'regionCode': regionCode,
        'interestIds': interestIds,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'onboardingCompleted': onboardingCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      coverPath: json['coverPath'] as String?,
      countryCode: json['countryCode'] as String?,
      regionCode: json['regionCode'] as String?,
      interestIds: (json['interestIds'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
