import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/core/widgets/studio_overview.dart';

class PageCategory {
  final String slug;
  final String nameKey;
  final int sortOrder;

  const PageCategory({required this.slug, required this.nameKey, required this.sortOrder});
  factory PageCategory.fromJson(Map<String, dynamic> json) => PageCategory(slug: json['slug'] as String, nameKey: json['name_key'] as String, sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0);
}

class PageStudioSummary {
  final String? myRole;
  final int followerCount;
  final int postCount;
  final int teamCount;
  final String verificationStatus;
  final DateTime? verifiedAt;
  final String status;

  const PageStudioSummary({this.myRole, required this.followerCount, required this.postCount, required this.teamCount, required this.verificationStatus, required this.status, this.verifiedAt});
  factory PageStudioSummary.fromJson(Map<String, dynamic> json) => PageStudioSummary(myRole: json['my_role'] as String?, followerCount: (json['follower_count'] as num?)?.toInt() ?? 0, postCount: (json['post_count'] as num?)?.toInt() ?? 0, teamCount: (json['team_count'] as num?)?.toInt() ?? 0, verificationStatus: json['verification_status'] as String? ?? 'none', verifiedAt: _date(json['verified_at']), status: json['status'] as String? ?? 'active');
}

class PageStudioStats {
  final StudioStats overview;
  final List<PageStudioFollower> latestFollowers;
  final List<PageStudioPost> topPosts;
  const PageStudioStats({required this.overview, required this.latestFollowers, required this.topPosts});

  factory PageStudioStats.fromJson(Map<String, dynamic> json) => PageStudioStats(
    overview: StudioStats.fromJson(json, const ['followers', 'posts', 'reactions', 'comments']),
    latestFollowers: _pageList(json['latest_followers']).map(PageStudioFollower.fromJson).toList(),
    topPosts: _pageList(json['top_posts']).map(PageStudioPost.fromJson).toList(),
  );
}

class PageStudioFollower {
  final UserProfile profile;
  final DateTime joinedAt;
  const PageStudioFollower({required this.profile, required this.joinedAt});
  factory PageStudioFollower.fromJson(Map<String, dynamic> json) => PageStudioFollower(profile: UserProfile.fromJson({...json, 'id': json['user_id']}), joinedAt: DateTime.parse(json['joined_at'].toString()).toUtc());
}

class PageStudioPost {
  final String id;
  final String preview;
  final String kind;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  const PageStudioPost({required this.id, required this.preview, required this.kind, required this.reactionCount, required this.commentCount, required this.createdAt});
  factory PageStudioPost.fromJson(Map<String, dynamic> json) => PageStudioPost(id: json['id'] as String, preview: json['preview'] as String? ?? '', kind: json['kind'] as String? ?? 'text', reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0, commentCount: (json['comment_count'] as num?)?.toInt() ?? 0, createdAt: DateTime.parse(json['created_at'].toString()).toUtc());
}

class CreatedPage {
  final String id;
  final String slug;

  const CreatedPage({required this.id, required this.slug});
}

class PageTeamMember {
  final String id;
  final String role;
  final DateTime createdAt;
  final UserProfile profile;

  const PageTeamMember({required this.id, required this.role, required this.createdAt, required this.profile});
  factory PageTeamMember.fromJson(Map<String, dynamic> json) => PageTeamMember(id: json['id'] as String, role: json['role'] as String, createdAt: DateTime.parse(json['created_at'] as String).toUtc(), profile: UserProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map)));
}

class CommunityPage {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String category;
  final String verificationStatus;
  final DateTime? verifiedAt;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final String? regionName;
  final String? regionId;
  final String countryCode;
  final String status;
  final int followerCount;
  final int postCount;
  final bool isFollowedByMe;
  final String? myRole;
  final DateTime createdAt;

  const CommunityPage({required this.id, required this.slug, required this.name, this.description, this.avatarUrl, this.coverUrl, required this.category, required this.verificationStatus, this.verifiedAt, this.website, this.phone, this.email, this.address, this.regionName, this.regionId, required this.countryCode, this.status = 'active', required this.followerCount, required this.postCount, this.isFollowedByMe = false, this.myRole, required this.createdAt});

  bool get isVerified => verificationStatus == 'verified';

  CommunityPage copyWith({int? followerCount, bool? isFollowedByMe, String? myRole}) => CommunityPage(id: id, slug: slug, name: name, description: description, avatarUrl: avatarUrl, coverUrl: coverUrl, category: category, verificationStatus: verificationStatus, verifiedAt: verifiedAt, website: website, phone: phone, email: email, address: address, regionName: regionName, regionId: regionId, countryCode: countryCode, status: status, followerCount: followerCount ?? this.followerCount, postCount: postCount, isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe, myRole: myRole ?? this.myRole, createdAt: createdAt);

  factory CommunityPage.fromJson(Map<String, dynamic> json) => CommunityPage(
    id: json['id'] as String,
    slug: json['slug'].toString(),
    name: json['name'] as String,
    description: json['description'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    category: json['category'] as String,
    verificationStatus: json['verification_status'] as String? ?? 'none',
    verifiedAt: json['verified_at'] == null ? null : DateTime.tryParse(json['verified_at'].toString())?.toUtc(),
    website: json['website'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    address: json['address'] as String?,
    regionName: (json['region'] as Map?)?['name'] as String?,
    regionId: json['region_id'] as String?,
    countryCode: json['country_code'] as String? ?? 'IT',
    status: json['status'] as String? ?? 'active',
    followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
    postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    isFollowedByMe: json['is_followed_by_me'] as bool? ?? false,
    myRole: json['my_role'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );

}

List<Map<String, dynamic>> _pageList(Object? value) => (value as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();