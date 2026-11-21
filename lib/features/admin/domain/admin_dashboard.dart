class DashboardMetric {
  final int? value;
  final String? errorKey;

  const DashboardMetric.success(this.value) : errorKey = null;
  const DashboardMetric.failure(this.errorKey) : value = null;
}

class DailyCount {
  final DateTime day;
  final int registrations;
  final int posts;

  const DailyCount({required this.day, required this.registrations, required this.posts});
}

class DashboardPerson {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const DashboardPerson({required this.id, required this.displayName, this.avatarUrl});

  factory DashboardPerson.fromJson(Map<String, dynamic>? json) => DashboardPerson(
    id: json?['id'] as String? ?? '',
    displayName: json?['display_name'] as String? ?? '',
    avatarUrl: json?['avatar_url'] as String?,
  );
}

class DashboardReport {
  final String id;
  final String priority;
  final String reason;
  final String targetType;
  final DateTime createdAt;
  final DashboardPerson? reporter;
  final DashboardPerson? targetAuthor;

  const DashboardReport({required this.id, required this.priority, required this.reason, required this.targetType, required this.createdAt, this.reporter, this.targetAuthor});

  factory DashboardReport.fromJson(Map<String, dynamic> json) => DashboardReport(
    id: json['id'] as String,
    priority: json['priority'] as String,
    reason: json['reason'] as String,
    targetType: json['target_type'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    reporter: json['reporter'] == null ? null : DashboardPerson.fromJson(json['reporter'] as Map<String, dynamic>),
    targetAuthor: json['target_author'] == null ? null : DashboardPerson.fromJson(json['target_author'] as Map<String, dynamic>),
  );
}

class DashboardBadgeRequest {
  final String id;
  final String badgeType;
  final DateTime createdAt;
  final DashboardPerson user;

  const DashboardBadgeRequest({required this.id, required this.badgeType, required this.createdAt, required this.user});

  factory DashboardBadgeRequest.fromJson(Map<String, dynamic> json) => DashboardBadgeRequest(
    id: json['id'] as String,
    badgeType: json['badge_type'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    user: DashboardPerson.fromJson(json['user'] as Map<String, dynamic>?),
  );
}

class DashboardAuditEntry {
  final String id;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final DateTime createdAt;
  final DashboardPerson? admin;

  const DashboardAuditEntry({required this.id, required this.action, this.resourceType, this.resourceId, required this.createdAt, this.admin});

  factory DashboardAuditEntry.fromJson(Map<String, dynamic> json) => DashboardAuditEntry(
    id: json['id'] as String,
    action: json['action'] as String,
    resourceType: json['resource_type'] as String?,
    resourceId: json['resource_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    admin: json['admin'] == null ? null : DashboardPerson.fromJson(json['admin'] as Map<String, dynamic>),
  );
}

class DashboardData {
  final DashboardMetric totalUsers;
  final DashboardMetric newUsersCurrent;
  final DashboardMetric newUsersPrevious;
  final DashboardMetric postsCurrent;
  final DashboardMetric postsPrevious;
  final DashboardMetric activeListings;
  final DashboardMetric openReports;
  final DashboardMetric pendingBadges;
  final DashboardMetric upcomingEvents;
  final DashboardMetric activeGroups;
  final List<DailyCount> dailyCounts;
  final List<DashboardReport> reports;
  final List<DashboardBadgeRequest> badgeRequests;
  final List<DashboardAuditEntry> auditEntries;

  const DashboardData({required this.totalUsers, required this.newUsersCurrent, required this.newUsersPrevious, required this.postsCurrent, required this.postsPrevious, required this.activeListings, required this.openReports, required this.pendingBadges, required this.upcomingEvents, required this.activeGroups, required this.dailyCounts, required this.reports, required this.badgeRequests, required this.auditEntries});
}