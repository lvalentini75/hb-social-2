class AdminModerationStats {
  final int open;
  final int unassigned;
  final int mine;
  final int overdue;
  final int dueSoon;
  final int resolvedToday;
  final int suspendedUsers;
  final int bannedUsers;
  final int pendingDeletions;
  final int exportsQueued;
  final double averageResolutionHours;
  final double withinSlaPercent;

  const AdminModerationStats({required this.open, required this.unassigned, required this.mine, required this.overdue, required this.dueSoon, required this.resolvedToday, required this.suspendedUsers, required this.bannedUsers, required this.pendingDeletions, required this.exportsQueued, required this.averageResolutionHours, required this.withinSlaPercent});

  factory AdminModerationStats.fromJson(Map<String, dynamic> json) => AdminModerationStats(
    open: _int(json['open']), unassigned: _int(json['unassigned']), mine: _int(json['mine']), overdue: _int(json['overdue']), dueSoon: _int(json['due_soon']), resolvedToday: _int(json['resolved_today']), suspendedUsers: _int(json['suspended_users']), bannedUsers: _int(json['banned_users']), pendingDeletions: _int(json['pending_deletions']), exportsQueued: _int(json['exports_queued']), averageResolutionHours: _double(json['avg_resolution_hours_7d']), withinSlaPercent: _double(json['within_sla_pct_7d']));
}

class AdminP41User {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final String countryCode;
  final String? regionName;
  final String verificationLevel;
  final String locale;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final DateTime? suspendedUntil;
  final DateTime? deletionRequestedAt;
  final int postCount;
  final int followerCount;
  final int activeStrikes;
  final int openReports;
  final String? adminRole;
  final int total;

  const AdminP41User({required this.id, required this.username, required this.displayName, this.avatarUrl, required this.status, required this.countryCode, this.regionName, required this.verificationLevel, required this.locale, required this.createdAt, this.lastSeenAt, this.suspendedUntil, this.deletionRequestedAt, required this.postCount, required this.followerCount, required this.activeStrikes, required this.openReports, this.adminRole, required this.total});

  factory AdminP41User.fromJson(Map<String, dynamic> json) => AdminP41User(id: '${json['id']}', username: '${json['username'] ?? ''}', displayName: '${json['display_name'] ?? ''}', avatarUrl: json['avatar_url']?.toString(), status: '${json['status'] ?? 'active'}', countryCode: '${json['country_code'] ?? ''}'.trim(), regionName: json['region_name']?.toString(), verificationLevel: '${json['verification_level'] ?? 'none'}', locale: '${json['locale'] ?? 'it'}', createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), lastSeenAt: _date(json['last_seen_at']), suspendedUntil: _date(json['suspended_until']), deletionRequestedAt: _date(json['deletion_requested_at']), postCount: _int(json['post_count']), followerCount: _int(json['follower_count']), activeStrikes: _int(json['active_strikes']), openReports: _int(json['open_reports']), adminRole: json['admin_role']?.toString(), total: _int(json['total']));
}

class AdminUserP41Detail {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> settings;
  final Map<String, int> counts;
  final String? adminRole;
  final Map<String, dynamic>? pendingVerification;
  final List<Map<String, dynamic>> strikes;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> recentReports;
  final List<Map<String, dynamic>> history;
  final List<DataExportRecord> exports;

  const AdminUserP41Detail({required this.profile, required this.settings, required this.counts, this.adminRole, this.pendingVerification, required this.strikes, required this.notes, required this.recentReports, required this.history, required this.exports});
  factory AdminUserP41Detail.fromJson(Map<String, dynamic> json) => AdminUserP41Detail(profile: _map(json['profile']), settings: _map(json['settings']), counts: {for (final entry in _map(json['counts']).entries) entry.key: _int(entry.value)}, adminRole: json['admin_role']?.toString(), pendingVerification: json['pending_verification'] is Map ? _map(json['pending_verification']) : null, strikes: _maps(json['strikes']), notes: _maps(json['notes']), recentReports: _maps(json['recent_reports']), history: _maps(json['history']), exports: [for (final item in _maps(json['exports'])) DataExportRecord.fromJson(item)]);
}

class AdminReportQueueItem {
  final Map<String, dynamic> json;
  const AdminReportQueueItem(this.json);
  String get id => '${json['id']}';
  String get status => '${json['status'] ?? 'open'}';
  String get priority => '${json['priority'] ?? 'low'}';
  String get targetType => '${json['target_type'] ?? ''}';
  String get reason => '${json['reason'] ?? 'other'}';
  String? get details => json['details']?.toString();
  String get slaStatus => '${json['sla_status'] ?? 'ok'}';
  int get minutesLeft => _int(json['minutes_left']);
  int get duplicates => _int(json['duplicates']);
  int get activeStrikes => _int(json['author_active_strikes']);
  int get total => _int(json['total']);
  String? get reporterName => json['reporter_name']?.toString();
  String? get authorName => json['author_name']?.toString();
  String? get authorUsername => json['author_username']?.toString();
  String? get authorStatus => json['author_status']?.toString();
  String? get assignedTo => json['assigned_to']?.toString();
  String? get assigneeName => json['assignee_name']?.toString();
  DateTime? get createdAt => _date(json['created_at']);
  Map<String, dynamic> get preview => _map(json['preview']);
}

class AdminReportP41Detail {
  final Map<String, dynamic> report;
  final Map<String, dynamic> preview;
  final Map<String, dynamic> reporter;
  final Map<String, dynamic> author;
  final Map<String, dynamic> assignee;
  final List<Map<String, dynamic>> sameTarget;
  final List<Map<String, dynamic>> authorHistory;
  final List<Map<String, dynamic>> strikes;
  const AdminReportP41Detail({required this.report, required this.preview, required this.reporter, required this.author, required this.assignee, required this.sameTarget, required this.authorHistory, required this.strikes});
  factory AdminReportP41Detail.fromJson(Map<String, dynamic> json) => AdminReportP41Detail(report: _map(json['report']), preview: _map(json['preview']), reporter: _map(json['reporter']), author: _map(json['author']), assignee: _map(json['assignee']), sameTarget: _maps(json['same_target']), authorHistory: _maps(json['author_history']), strikes: _maps(json['strikes']));
}

class ReportResolutionResult {
  final String resolution;
  final int closedReports;
  final bool strikeIssued;
  const ReportResolutionResult({required this.resolution, required this.closedReports, required this.strikeIssued});
  factory ReportResolutionResult.fromJson(Map<String, dynamic> json) => ReportResolutionResult(resolution: '${json['resolution'] ?? ''}', closedReports: _int(json['closed_reports']), strikeIssued: json['strike_issued'] == true);
}

class DataExportRecord {
  final String id;
  final String status;
  final int? fileSize;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  const DataExportRecord({required this.id, required this.status, this.fileSize, required this.requestedAt, this.completedAt, this.expiresAt});
  factory DataExportRecord.fromJson(Map<String, dynamic> json) => DataExportRecord(id: '${json['id']}', status: '${json['status'] ?? 'queued'}', fileSize: json['file_size'] == null ? null : _int(json['file_size']), requestedAt: _date(json['requested_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), completedAt: _date(json['completed_at']), expiresAt: _date(json['expires_at']));
}

class AccountDeletionStatus {
  final bool pending;
  final DateTime? requestedAt;
  final DateTime? eraseAfter;
  const AccountDeletionStatus({required this.pending, this.requestedAt, this.eraseAfter});
  factory AccountDeletionStatus.fromJson(Map<String, dynamic> json) => AccountDeletionStatus(pending: json['pending'] == true, requestedAt: _date(json['requested_at']), eraseAfter: _date(json['erase_after']));
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(Object? value) => value is List ? [for (final item in value) if (item is Map) Map<String, dynamic>.from(item)] : const [];
int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _double(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse('$value')?.toUtc();