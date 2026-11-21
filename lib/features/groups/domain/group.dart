import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/core/widgets/studio_overview.dart';

enum GroupFilter { all, mine }

class GroupMembership {
  final String role;
  final String status;

  const GroupMembership({required this.role, required this.status});

  factory GroupMembership.fromJson(Map<String, dynamic> json) => GroupMembership(role: json['role'] as String, status: json['status'] as String);

  bool get isActive => status == 'active';
  bool get canManage => isActive && const {'owner', 'admin', 'moderator'}.contains(role);
}

class GroupCategory {
  final String slug;
  final String nameKey;

  const GroupCategory({required this.slug, required this.nameKey});

  factory GroupCategory.fromJson(Map<String, dynamic> json) => GroupCategory(slug: json['slug'] as String, nameKey: json['name_key'] as String);
}

class GroupStudioSummary {
  final String role;
  final int memberCount;
  final int pendingCount;
  final int bannedCount;
  final int postCount;

  const GroupStudioSummary({required this.role, required this.memberCount, required this.pendingCount, required this.bannedCount, required this.postCount});

  factory GroupStudioSummary.fromJson(Map<String, dynamic> json) => GroupStudioSummary(
    role: json['my_role'] as String,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
    bannedCount: (json['banned_count'] as num?)?.toInt() ?? 0,
    postCount: (json['post_count'] as num?)?.toInt() ?? 0,
  );
}

class GroupStudioStats {
  final StudioStats overview;
  final List<GroupStudioPerson> latestMembers;
  final List<GroupStudioPost> topPosts;
  final List<GroupStudioContributor> topContributors;
  const GroupStudioStats({required this.overview, required this.latestMembers, required this.topPosts, required this.topContributors});

  factory GroupStudioStats.fromJson(Map<String, dynamic> json) => GroupStudioStats(
    overview: StudioStats.fromJson(json, const ['members', 'posts', 'reactions', 'comments']),
    latestMembers: _groupList(json['latest_members']).map(GroupStudioPerson.fromJson).toList(),
    topPosts: _groupList(json['top_posts']).map(GroupStudioPost.fromJson).toList(),
    topContributors: _groupList(json['top_contributors']).map(GroupStudioContributor.fromJson).toList(),
  );
}

class GroupStudioPerson {
  final UserProfile profile;
  final String role;
  final DateTime joinedAt;
  const GroupStudioPerson({required this.profile, required this.role, required this.joinedAt});
  factory GroupStudioPerson.fromJson(Map<String, dynamic> json) => GroupStudioPerson(profile: UserProfile.fromJson({...json, 'id': json['user_id']}), role: json['role'] as String? ?? 'member', joinedAt: DateTime.parse(json['joined_at'].toString()).toUtc());
}

class GroupStudioPost {
  final String id;
  final String preview;
  final String kind;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  const GroupStudioPost({required this.id, required this.preview, required this.kind, required this.reactionCount, required this.commentCount, required this.createdAt});
  factory GroupStudioPost.fromJson(Map<String, dynamic> json) => GroupStudioPost(id: json['id'] as String, preview: json['preview'] as String? ?? '', kind: json['kind'] as String? ?? 'text', reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0, commentCount: (json['comment_count'] as num?)?.toInt() ?? 0, createdAt: DateTime.parse(json['created_at'].toString()).toUtc());
}

class GroupStudioContributor {
  final UserProfile profile;
  final int posts;
  const GroupStudioContributor({required this.profile, required this.posts});
  factory GroupStudioContributor.fromJson(Map<String, dynamic> json) => GroupStudioContributor(profile: UserProfile.fromJson({...json, 'id': json['user_id']}), posts: (json['posts'] as num?)?.toInt() ?? 0);
}

class Group {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String visibility;
  final String joinPolicy;
  final String? category;
  final String countryCode;
  final String? regionId;
  final int memberCount;
  final int postCount;
  final String status;
  final GroupMembership? myMembership;
  final DateTime createdAt;

  const Group({required this.id, required this.slug, required this.name, this.description, this.avatarUrl, this.coverUrl, required this.visibility, required this.joinPolicy, this.category, required this.countryCode, this.regionId, required this.memberCount, required this.postCount, required this.status, this.myMembership, required this.createdAt});

  bool get isPublic => visibility == 'public';
  bool get isMember => myMembership?.isActive == true;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    visibility: json['visibility'] as String? ?? 'public',
    joinPolicy: json['join_policy'] as String? ?? 'open',
    category: json['category'] as String?,
    countryCode: json['country_code'] as String,
    regionId: json['region_id'] as String?,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'active',
    myMembership: json['my_membership'] is Map ? GroupMembership.fromJson(Map<String, dynamic>.from(json['my_membership'] as Map)) : null,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );
}

class GroupMember {
  final String id;
  final UserProfile profile;
  final String role;
  final String status;
  final DateTime createdAt;
  final String? banReason;
  final DateTime? bannedAt;

  const GroupMember({required this.id, required this.profile, required this.role, required this.status, required this.createdAt, this.banReason, this.bannedAt});

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    id: json['id'] as String,
    profile: UserProfile.fromJson(Map<String, dynamic>.from(json['profile'] as Map)),
    role: json['role'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    banReason: json['ban_reason'] as String?,
    bannedAt: json['banned_at'] == null ? null : DateTime.parse(json['banned_at'] as String).toUtc(),
  );
}

List<Map<String, dynamic>> _groupList(Object? value) => (value as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList();