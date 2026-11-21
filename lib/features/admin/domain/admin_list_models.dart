import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/billing/domain/payment_method.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';

class AdminUserRecord {
  final UserProfile profile;
  final DateTime? lastSeenAt;

  const AdminUserRecord({required this.profile, this.lastSeenAt});

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) => AdminUserRecord(
    profile: UserProfile.fromJson(json),
    lastSeenAt: json['last_seen_at'] == null ? null : DateTime.tryParse(json['last_seen_at'] as String)?.toUtc(),
  );
}

class AdminPerson {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final String countryCode;

  const AdminPerson({required this.id, required this.username, required this.displayName, this.avatarUrl, this.verificationLevel = 'none', this.countryCode = ''});

  factory AdminPerson.fromJson(Map<String, dynamic> json) => AdminPerson(id: json['id'] as String, username: json['username'] as String? ?? '', displayName: json['display_name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?, verificationLevel: json['verification_level'] as String? ?? 'none', countryCode: json['country_code'] as String? ?? '');
}

class AdminReportRecord {
  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String? details;
  final String priority;
  final String status;
  final String countryCode;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final AdminPerson? reporter;
  final AdminPerson? targetAuthor;
  final AdminPerson? assignee;

  const AdminReportRecord({required this.id, required this.targetType, required this.targetId, required this.reason, this.details, required this.priority, required this.status, required this.countryCode, this.resolution, required this.createdAt, required this.updatedAt, this.resolvedAt, this.reporter, this.targetAuthor, this.assignee});

  factory AdminReportRecord.fromJson(Map<String, dynamic> json) => AdminReportRecord(
    id: json['id'] as String,
    targetType: json['target_type'] as String,
    targetId: json['target_id'] as String,
    reason: json['reason'] as String,
    details: json['details'] as String?,
    priority: json['priority'] as String,
    status: json['status'] as String,
    countryCode: (json['country_code'] as String).trim(),
    resolution: json['resolution'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    resolvedAt: json['resolved_at'] == null ? null : DateTime.tryParse(json['resolved_at'] as String)?.toUtc(),
    reporter: _person(json['reporter']),
    targetAuthor: _person(json['target_author']),
    assignee: _person(json['assignee']),
  );
}

class AdminVerificationRequest {
  final String id;
  final String badgeType;
  final String status;
  final List<AdminVerificationDocument> documents;
  final Map<String, dynamic> declaredData;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final AdminPerson user;
  final AdminPerson? reviewer;
  final AdminVerificationPage? page;
  final DateTime? documentsPurgedAt;

  const AdminVerificationRequest({required this.id, required this.badgeType, required this.status, this.documents = const [], required this.declaredData, this.rejectionReason, this.reviewedAt, this.expiresAt, required this.createdAt, required this.user, this.reviewer, this.page, this.documentsPurgedAt});

  factory AdminVerificationRequest.fromJson(Map<String, dynamic> json) => AdminVerificationRequest(
    id: json['id'] as String,
    badgeType: json['badge_type'] as String,
    status: json['status'] as String,
    documents: [for (final raw in json['documents'] as List? ?? const []) if (raw is Map) AdminVerificationDocument.fromJson(Map<String, dynamic>.from(raw))],
    declaredData: Map<String, dynamic>.from((json['declared_data'] as Map?) ?? const {}),
    rejectionReason: json['rejection_reason'] as String?,
    reviewedAt: json['reviewed_at'] == null ? null : DateTime.tryParse(json['reviewed_at'] as String)?.toUtc(),
    expiresAt: json['expires_at'] == null ? null : DateTime.tryParse(json['expires_at'] as String)?.toLocal(),
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    user: AdminPerson.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    reviewer: _person(json['reviewer']),
    page: json['page'] is Map ? AdminVerificationPage.fromJson(Map<String, dynamic>.from(json['page'] as Map)) : null,
    documentsPurgedAt: json['documents_purged_at'] == null ? null : DateTime.tryParse(json['documents_purged_at'].toString())?.toUtc(),
  );
}

class AdminVerificationDocument {
  final String path;
  final String kind;
  final String name;
  final int size;

  const AdminVerificationDocument({required this.path, required this.kind, required this.name, required this.size});
  factory AdminVerificationDocument.fromJson(Map<String, dynamic> json) => AdminVerificationDocument(path: json['path'] as String? ?? '', kind: json['kind'] as String? ?? 'other', name: json['name'] as String? ?? '', size: (json['size'] as num?)?.toInt() ?? 0);
}

class AdminVerificationPage {
  final String id;
  final String slug;
  final String name;
  final String category;

  const AdminVerificationPage({required this.id, required this.slug, required this.name, required this.category});
  factory AdminVerificationPage.fromJson(Map<String, dynamic> json) => AdminVerificationPage(id: json['id'] as String? ?? '', slug: json['slug'] as String? ?? '', name: json['name'] as String? ?? '', category: json['category'] as String? ?? '');
}

class AdminVerificationStats {
  final int pending;
  final int pendingOldestDays;
  final int approved30d;
  final int rejected30d;
  final int expiring30d;
  final int verifiedUsers;
  final int verifiedPages;
  final int docsAwaitingPurge;
  final Map<String, int> byType;

  const AdminVerificationStats({required this.pending, required this.pendingOldestDays, required this.approved30d, required this.rejected30d, required this.expiring30d, required this.verifiedUsers, required this.verifiedPages, required this.docsAwaitingPurge, required this.byType});
  factory AdminVerificationStats.fromJson(Map<String, dynamic> json) => AdminVerificationStats(pending: (json['pending'] as num?)?.toInt() ?? 0, pendingOldestDays: (json['pending_oldest_days'] as num?)?.toInt() ?? 0, approved30d: (json['approved_30d'] as num?)?.toInt() ?? 0, rejected30d: (json['rejected_30d'] as num?)?.toInt() ?? 0, expiring30d: (json['expiring_30d'] as num?)?.toInt() ?? 0, verifiedUsers: (json['verified_users'] as num?)?.toInt() ?? 0, verifiedPages: (json['verified_pages'] as num?)?.toInt() ?? 0, docsAwaitingPurge: (json['docs_awaiting_purge'] as num?)?.toInt() ?? 0, byType: {for (final entry in (json['by_type'] as Map? ?? const {}).entries) entry.key.toString(): (entry.value as num?)?.toInt() ?? 0});
}

class AdminVerificationMaintenanceResult {
  final int expired;
  final int reminded;
  final DateTime? ranAt;

  const AdminVerificationMaintenanceResult({required this.expired, required this.reminded, this.ranAt});
  factory AdminVerificationMaintenanceResult.fromJson(Map<String, dynamic> json) => AdminVerificationMaintenanceResult(expired: (json['expired'] as num?)?.toInt() ?? 0, reminded: (json['reminded'] as num?)?.toInt() ?? 0, ranAt: json['ran_at'] == null ? null : DateTime.tryParse(json['ran_at'].toString())?.toUtc());
}

class AdminListingRecord {
  final Listing listing;
  final int reportCount;

  const AdminListingRecord({required this.listing, this.reportCount = 0});
}

class AdminUserDetail {
  final String? adminRole;
  final int reportCount;
  final List<AdminReportRecord> reports;
  final List<AdminVerificationRequest> requests;
  final List<BillingPaymentMethod> paymentMethods;

  const AdminUserDetail({this.adminRole, required this.reportCount, required this.reports, required this.requests, required this.paymentMethods});
}

class AdminReportPreview {
  final String title;
  final String? text;
  final String? mediaUrl;
  final String? subtitle;
  final bool removed;
  final AdCreative? adCreative;
  final String? advertiserName;
  final String? adAccountId;
  final String? campaignName;

  const AdminReportPreview({required this.title, this.text, this.mediaUrl, this.subtitle, this.removed = false, this.adCreative, this.advertiserName, this.adAccountId, this.campaignName});
}

class AdminListingDetail {
  final int sellerActiveCount;
  final List<AdminReportRecord> reports;
  final Map<String, dynamic>? firearmsPolicy;

  const AdminListingDetail({required this.sellerActiveCount, required this.reports, this.firearmsPolicy});
}

class AdminPageResult<T> {
  final Page<T> page;
  final int count;

  const AdminPageResult({required this.page, required this.count});
}

class AdminCalendarRecord {
  final HuntingCalendar calendar;
  final String regionName;
  final String? huntingUnitName;
  final String? publisherName;
  final DateTime createdAt;

  const AdminCalendarRecord({required this.calendar, required this.regionName, this.huntingUnitName, this.publisherName, required this.createdAt});

  factory AdminCalendarRecord.fromJson(Map<String, dynamic> json) => AdminCalendarRecord(
    calendar: HuntingCalendar.fromJson(json),
    regionName: (json['region'] as Map?)?['name'] as String? ?? '',
    huntingUnitName: (json['hunting_unit'] as Map?)?['name'] as String?,
    publisherName: (json['publisher'] as Map?)?['display_name'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );
}

class AdminRoleRecord {
  final String id;
  final String name;
  final String? description;
  final Map<String, String> permissions;
  final int staffCount;

  const AdminRoleRecord({required this.id, required this.name, this.description, required this.permissions, required this.staffCount});
}

class AdminStaffRecord {
  final AdminPerson person;
  final String roleName;
  final bool mfaEnabled;
  final AdminPerson? addedBy;
  final DateTime createdAt;

  const AdminStaffRecord({required this.person, required this.roleName, required this.mfaEnabled, this.addedBy, required this.createdAt});

  factory AdminStaffRecord.fromJson(Map<String, dynamic> json) => AdminStaffRecord(
    person: AdminPerson.fromJson(Map<String, dynamic>.from(json['profile'] as Map)),
    roleName: (json['role'] as Map)['name'] as String,
    mfaEnabled: json['mfa_enabled'] as bool? ?? false,
    addedBy: _person(json['creator']),
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );
}

class AdminRolesData {
  final List<AdminRoleRecord> roles;
  final List<AdminStaffRecord> staff;

  const AdminRolesData({required this.roles, required this.staff});
}

class AdminFeatureFlag {
  final String id;
  final String module;
  final String? countryCode;
  final bool isEnabled;
  final int rolloutPercentage;
  final String? description;
  final DateTime updatedAt;

  const AdminFeatureFlag({required this.id, required this.module, this.countryCode, required this.isEnabled, required this.rolloutPercentage, this.description, required this.updatedAt});

  factory AdminFeatureFlag.fromJson(Map<String, dynamic> json) => AdminFeatureFlag(id: json['id'] as String, module: json['module'] as String, countryCode: (json['country_code'] as String?)?.trim(), isEnabled: json['is_enabled'] as bool? ?? false, rolloutPercentage: (json['rollout_percentage'] as num).toInt(), description: json['description'] as String?, updatedAt: DateTime.parse(json['updated_at'] as String).toUtc());
}

class AdminCountryPolicy {
  final String id;
  final String countryCode;
  final String policyType;
  final Map<String, dynamic> policyData;
  final DateTime updatedAt;

  const AdminCountryPolicy({required this.id, required this.countryCode, required this.policyType, required this.policyData, required this.updatedAt});

  factory AdminCountryPolicy.fromJson(Map<String, dynamic> json) => AdminCountryPolicy(id: json['id'] as String, countryCode: (json['country_code'] as String).trim(), policyType: json['policy_type'] as String, policyData: Map<String, dynamic>.from(json['policy_data'] as Map? ?? const {}), updatedAt: DateTime.parse(json['updated_at'] as String).toUtc());
}

class AdminPlatformConfiguration {
  final List<AdminCountryRecord> countries;
  final List<AdminFeatureFlag> flags;
  final List<AdminCountryPolicy> policies;
  final List<AdminExchangeRate> exchangeRates;

  const AdminPlatformConfiguration({required this.countries, required this.flags, required this.policies, required this.exchangeRates});
}

class AdminCountryRecord {
  final String code;
  final String name;
  final String currencyCode;
  final String locale;
  final String unitSystem;
  final bool isActive;
  final int regionCount;
  final int userCount;

  const AdminCountryRecord({required this.code, required this.name, required this.currencyCode, required this.locale, required this.unitSystem, required this.isActive, required this.regionCount, required this.userCount});
}

class AdminCountryPolicyOverview {
  final String countryCode;
  final String countryName;
  final bool isActive;
  final String firearmsMode;
  final String requiresBadge;
  final List<String> allowedTypes;
  final String noticeKey;
  final int minimumAge;
  final bool blurHarvestPhotos;
  final bool allowHarvestPhotos;
  final int firearmsListings;
  final int gunShopsVerified;
  final DateTime? updatedAt;
  final bool hasExplicitPolicy;

  const AdminCountryPolicyOverview({required this.countryCode, required this.countryName, required this.isActive, required this.firearmsMode, required this.requiresBadge, required this.allowedTypes, required this.noticeKey, required this.minimumAge, required this.blurHarvestPhotos, required this.allowHarvestPhotos, required this.firearmsListings, required this.gunShopsVerified, this.updatedAt, required this.hasExplicitPolicy});
  factory AdminCountryPolicyOverview.fromJson(Map<String, dynamic> json) => AdminCountryPolicyOverview(countryCode: json['country_code'] as String? ?? '', countryName: json['country_name'] as String? ?? '', isActive: json['is_active'] as bool? ?? false, firearmsMode: json['firearms_mode'] as String? ?? 'disabled', requiresBadge: json['requires_badge'] as String? ?? 'hunter', allowedTypes: (json['allowed_types'] as List? ?? const []).map((item) => item.toString()).toList(), noticeKey: json['notice_key'] as String? ?? 'marketplace.firearms.notice.disabled', minimumAge: (json['minimum_age'] as num?)?.toInt() ?? 18, blurHarvestPhotos: json['blur_harvest_photos'] as bool? ?? true, allowHarvestPhotos: json['allow_harvest_photos'] as bool? ?? true, firearmsListings: (json['firearms_listings'] as num?)?.toInt() ?? 0, gunShopsVerified: (json['gun_shops_verified'] as num?)?.toInt() ?? 0, updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString())?.toUtc(), hasExplicitPolicy: json['has_explicit_policy'] == true || ((json['explicit_policy_count'] as num?)?.toInt() ?? 0) > 0);
}

class AdminExchangeRate {
  final String id;
  final String baseCode;
  final String quoteCode;
  final String rate;
  final DateTime validOn;
  final String? source;

  const AdminExchangeRate({required this.id, required this.baseCode, required this.quoteCode, required this.rate, required this.validOn, this.source});

  factory AdminExchangeRate.fromJson(Map<String, dynamic> json) => AdminExchangeRate(id: json['id'] as String, baseCode: (json['base_code'] as String).trim(), quoteCode: (json['quote_code'] as String).trim(), rate: json['rate'].toString(), validOn: DateTime.parse(json['valid_on'] as String), source: json['source'] as String?);
}

class AdminCalendarOptions {
  final Map<String, String> regions;
  final List<String> countries;
  final List<String> statuses;
  final List<String> seasons;
  final List<String> categories;

  const AdminCalendarOptions({required this.regions, required this.countries, required this.statuses, required this.seasons, required this.categories});
}

class AdminSpeciesRecord {
  final SpeciesInfo species;
  final int publishedCalendarCount;

  const AdminSpeciesRecord({required this.species, required this.publishedCalendarCount});
}

class AdminAuditOptions {
  final List<String> actions;
  final List<String> resourceTypes;
  final List<AdminPerson> admins;

  const AdminAuditOptions({required this.actions, required this.resourceTypes, required this.admins});
}

class AdminAuditRecord {
  final String id;
  final AdminPerson? admin;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? resourceSlug;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  const AdminAuditRecord({required this.id, this.admin, required this.action, this.resourceType, this.resourceId, this.resourceSlug, this.changes, required this.createdAt});

  factory AdminAuditRecord.fromJson(Map<String, dynamic> json) => AdminAuditRecord(id: json['id'] as String, admin: _person(json['admin']), action: json['action'] as String, resourceType: json['resource_type'] as String?, resourceId: json['resource_id'] as String?, resourceSlug: json['resource_slug'] as String?, changes: json['changes'] == null ? null : Map<String, dynamic>.from(json['changes'] as Map), createdAt: DateTime.parse(json['created_at'] as String).toUtc());
}

AdminPerson? _person(dynamic value) => value is Map ? AdminPerson.fromJson(Map<String, dynamic>.from(value)) : null;

class AdminPostRecord {
  final FeedPost post;
  final String status;
  final String visibility;
  final bool isSensitive;
  final String countryCode;
  final String? groupName;
  final String? groupSlug;
  final String? pageName;
  final String? pageSlug;

  const AdminPostRecord({required this.post, required this.status, required this.visibility, required this.isSensitive, required this.countryCode, this.groupName, this.groupSlug, this.pageName, this.pageSlug});
}

class AdminStoryRecord {
  final String id;
  final AdminPerson author;
  final String mediaUrl;
  final String kind;
  final String? caption;
  final int viewCount;
  final String status;
  final String countryCode;
  final DateTime expiresAt;
  final DateTime createdAt;

  const AdminStoryRecord({required this.id, required this.author, required this.mediaUrl, required this.kind, this.caption, required this.viewCount, required this.status, required this.countryCode, required this.expiresAt, required this.createdAt});
}

class AdminCommentRecord {
  final String id;
  final AdminPerson author;
  final String postId;
  final String postExcerpt;
  final String content;
  final int reactionCount;
  final String status;
  final DateTime createdAt;

  const AdminCommentRecord({required this.id, required this.author, required this.postId, required this.postExcerpt, required this.content, required this.reactionCount, required this.status, required this.createdAt});
}

class AdminPostDetail {
  final List<AdminCommentRecord> comments;
  final List<AdminReportRecord> reports;
  const AdminPostDetail({required this.comments, required this.reports});
}

class AdminCommunityRecord {
  final String id;
  final String kind;
  final String slug;
  final String name;
  final String? description;
  final String? avatarUrl;
  final AdminPerson owner;
  final String status;
  final String countryCode;
  final String? regionId;
  final String? regionName;
  final String? category;
  final String? visibility;
  final String? joinPolicy;
  final String? verificationStatus;
  final DateTime? verifiedAt;
  final int memberCount;
  final int contentCount;
  final int followerCount;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime createdAt;

  const AdminCommunityRecord({required this.id, required this.kind, required this.slug, required this.name, this.description, this.avatarUrl, required this.owner, required this.status, required this.countryCode, this.regionId, this.regionName, this.category, this.visibility, this.joinPolicy, this.verificationStatus, this.verifiedAt, this.memberCount = 0, this.contentCount = 0, this.followerCount = 0, this.website, this.phone, this.email, this.address, required this.createdAt});
}

class AdminMembershipRecord {
  final String id;
  final AdminPerson person;
  final String role;
  final String? status;
  const AdminMembershipRecord({required this.id, required this.person, required this.role, this.status});
}

class AdminThreadSummary {
  final String id;
  final String title;
  final AdminPerson author;
  final int replyCount;
  final bool isPinned;
  final bool isLocked;
  final bool isSolved;
  const AdminThreadSummary({required this.id, required this.title, required this.author, required this.replyCount, required this.isPinned, required this.isLocked, required this.isSolved});
}

class AdminCommunityDetail {
  final List<AdminMembershipRecord> members;
  final List<AdminPostRecord> posts;
  final List<AdminThreadSummary> threads;
  const AdminCommunityDetail({this.members = const [], this.posts = const [], this.threads = const []});
}

class AdminEventRecord {
  final HuntingEvent event;
  final String status;
  final String countryCode;
  final String? regionId;
  const AdminEventRecord({required this.event, required this.status, required this.countryCode, this.regionId});
}

class AdminEventDetail {
  final List<EventParticipant> participants;
  const AdminEventDetail({required this.participants});
}
