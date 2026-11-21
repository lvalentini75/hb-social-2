import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/core/widgets/studio_overview.dart';

class ForumStudioStats {
  final int days;
  final ForumStudioMetrics totals;
  final ForumStudioMetrics period;
  final ForumStudioMetrics previous;
  final List<ForumStudioPoint> series;
  final List<ForumStudioMember> latestMembers;
  final List<ForumStudioTopThread> topThreads;
  final List<ForumStudioContributor> topContributors;

  const ForumStudioStats({required this.days, required this.totals, required this.period, required this.previous, required this.series, required this.latestMembers, required this.topThreads, required this.topContributors});

  factory ForumStudioStats.fromJson(Map<String, dynamic> json) => ForumStudioStats(
    days: (json['days'] as num?)?.toInt() ?? 30,
    totals: ForumStudioMetrics.fromJson(_map(json['totals'])),
    period: ForumStudioMetrics.fromJson(_map(json['period'])),
    previous: ForumStudioMetrics.fromJson(_map(json['previous'])),
    series: _list(json['series']).map(ForumStudioPoint.fromJson).toList(),
    latestMembers: _list(json['latest_members']).map(ForumStudioMember.fromJson).toList(),
    topThreads: _list(json['top_threads']).map(ForumStudioTopThread.fromJson).toList(),
    topContributors: _list(json['top_contributors']).map(ForumStudioContributor.fromJson).toList(),
  );

  StudioStats get overview => StudioStats(
    days: days,
    totals: StudioMetrics({'members': totals.members, 'threads': totals.threads, 'replies': totals.replies, 'views': totals.views}),
    period: StudioMetrics({'members': period.members, 'threads': period.threads, 'replies': period.replies, 'views': period.views}),
    previous: StudioMetrics({'members': previous.members, 'threads': previous.threads, 'replies': previous.replies, 'views': previous.views}),
    series: series.map((point) => StudioSeriesPoint(day: point.day, metrics: StudioMetrics({'members': point.metrics.members, 'threads': point.metrics.threads, 'replies': point.metrics.replies, 'views': point.metrics.views}))).toList(),
  );
}

class ForumStudioMetrics {
  final int members;
  final int threads;
  final int replies;
  final int views;
  const ForumStudioMetrics({required this.members, required this.threads, required this.replies, required this.views});
  factory ForumStudioMetrics.fromJson(Map<String, dynamic> json) => ForumStudioMetrics(members: _int(json['members']), threads: _int(json['threads']), replies: _int(json['replies']), views: _int(json['views']));
  int value(String key) => switch (key) {'members' => members, 'threads' => threads, 'views' => views, _ => replies};
}

class ForumStudioPoint {
  final DateTime day;
  final ForumStudioMetrics metrics;
  const ForumStudioPoint({required this.day, required this.metrics});
  factory ForumStudioPoint.fromJson(Map<String, dynamic> json) => ForumStudioPoint(day: DateTime.parse(json['day'].toString()).toLocal(), metrics: ForumStudioMetrics.fromJson(json));
}

class ForumStudioMember {
  final UserProfile profile;
  final String role;
  final DateTime joinedAt;
  const ForumStudioMember({required this.profile, required this.role, required this.joinedAt});
  factory ForumStudioMember.fromJson(Map<String, dynamic> json) => ForumStudioMember(profile: UserProfile.fromJson({...json, 'id': json['user_id']}), role: json['role'] as String? ?? 'member', joinedAt: DateTime.parse(json['joined_at'].toString()).toUtc());
}

class ForumStudioTopThread {
  final String id;
  final String title;
  final int viewCount;
  final int replyCount;
  final bool isPinned;
  final bool solved;
  const ForumStudioTopThread({required this.id, required this.title, required this.viewCount, required this.replyCount, required this.isPinned, required this.solved});
  factory ForumStudioTopThread.fromJson(Map<String, dynamic> json) => ForumStudioTopThread(id: json['id'] as String, title: json['title'] as String? ?? '', viewCount: _int(json['view_count']), replyCount: _int(json['reply_count']), isPinned: json['is_pinned'] as bool? ?? false, solved: json['solved'] as bool? ?? false);
}

class ForumStudioContributor {
  final UserProfile profile;
  final int replies;
  const ForumStudioContributor({required this.profile, required this.replies});
  factory ForumStudioContributor.fromJson(Map<String, dynamic> json) => ForumStudioContributor(profile: UserProfile.fromJson({...json, 'id': json['user_id']}), replies: _int(json['replies']));
}

class ForumReport {
  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String? details;
  final String priority;
  final String status;
  final DateTime createdAt;
  final String reporterUsername;
  final String authorUsername;
  final String authorDisplayName;
  final String threadId;
  final String threadTitle;
  final String preview;

  const ForumReport({required this.id, required this.targetType, required this.targetId, required this.reason, this.details, required this.priority, required this.status, required this.createdAt, required this.reporterUsername, required this.authorUsername, required this.authorDisplayName, required this.threadId, required this.threadTitle, required this.preview});
  factory ForumReport.fromJson(Map<String, dynamic> json) => ForumReport(id: json['id'] as String, targetType: json['target_type'] as String, targetId: json['target_id'] as String, reason: json['reason'] as String, details: json['details'] as String?, priority: json['priority'] as String? ?? 'normal', status: json['status'] as String? ?? 'open', createdAt: DateTime.parse(json['created_at'].toString()).toUtc(), reporterUsername: json['reporter_username'] as String? ?? '', authorUsername: json['author_username'] as String? ?? '', authorDisplayName: json['author_display_name'] as String? ?? '', threadId: json['thread_id'] as String, threadTitle: json['thread_title'] as String? ?? '', preview: json['preview'] as String? ?? '');
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _list(Object? value) => (value as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList();