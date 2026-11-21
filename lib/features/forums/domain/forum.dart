import 'package:hb_social/features/profile/domain/user_profile.dart';

class ForumMembership {
  final String role;
  final String status;

  const ForumMembership({required this.role, required this.status});

  factory ForumMembership.fromJson(Map<String, dynamic> json) => ForumMembership(role: json['role'] as String, status: json['status'] as String);

  bool get isActive => status == 'active';
  bool get canManage => isActive && const {'owner', 'moderator'}.contains(role);
}

class ForumCategory {
  final String slug;
  final String nameKey;

  const ForumCategory({required this.slug, required this.nameKey});

  factory ForumCategory.fromJson(Map<String, dynamic> json) => ForumCategory(slug: json['slug'] as String, nameKey: json['name_key'] as String);
}

class ForumStudioSummary {
  final String? myRole;
  final int memberCount;
  final int pendingCount;
  final int bannedCount;
  final int threadCount;

  const ForumStudioSummary({this.myRole, required this.memberCount, required this.pendingCount, required this.bannedCount, required this.threadCount});

  factory ForumStudioSummary.fromJson(Map<String, dynamic> json) => ForumStudioSummary(myRole: json['my_role'] as String?, memberCount: (json['member_count'] as num?)?.toInt() ?? 0, pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0, bannedCount: (json['banned_count'] as num?)?.toInt() ?? 0, threadCount: (json['thread_count'] as num?)?.toInt() ?? 0);
}

class ForumMember {
  final String id;
  final UserProfile profile;
  final String role;
  final String status;
  final DateTime createdAt;
  final String? banReason;
  final DateTime? bannedAt;
  final DateTime? lastSeenAt;

  const ForumMember({required this.id, required this.profile, required this.role, required this.status, required this.createdAt, this.banReason, this.bannedAt, this.lastSeenAt});

  factory ForumMember.fromJson(Map<String, dynamic> json) => ForumMember(
    id: json['id'] as String,
    profile: UserProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    role: json['role'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    banReason: json['ban_reason'] as String?,
    bannedAt: json['banned_at'] == null ? null : DateTime.parse(json['banned_at'] as String).toUtc(),
    lastSeenAt: json['user'] is Map && (json['user'] as Map)['last_seen_at'] != null ? DateTime.parse((json['user'] as Map)['last_seen_at'] as String).toUtc() : null,
  );
}

class Forum {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? category;
  final String visibility;
  final String ownerId;
  final String countryCode;
  final int memberCount;
  final int threadCount;
  final String status;
  final String? avatarUrl;
  final String? coverUrl;
  final ForumMembership? myMembership;
  final String? myRole;
  final DateTime createdAt;

  const Forum({required this.id, required this.slug, required this.name, this.description, this.category, required this.visibility, required this.ownerId, required this.countryCode, required this.memberCount, required this.threadCount, required this.status, this.avatarUrl, this.coverUrl, this.myMembership, this.myRole, required this.createdAt});

  bool get isPrivate => visibility == 'private';

  factory Forum.fromJson(Map<String, dynamic> json) => Forum(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    category: json['category'] as String?,
    visibility: json['visibility'] as String,
    ownerId: json['owner_id'] as String,
    countryCode: (json['country_code'] as String).trim(),
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    threadCount: (json['thread_count'] as num?)?.toInt() ?? 0,
    status: json['status'] as String,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    myMembership: json['my_membership'] is Map ? ForumMembership.fromJson(Map<String, dynamic>.from(json['my_membership'] as Map)) : null,
    myRole: json['my_role'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );
}