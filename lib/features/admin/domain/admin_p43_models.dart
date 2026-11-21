DateTime? p43Date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();

class AdminAuthStats {
  final int periodDays;
  final int totalUsers;
  final int withPassword;
  final int socialOnly;
  final int signupsPeriod;
  final List<Map<String, dynamic>> byProvider;
  final Map<String, dynamic> settings;
  const AdminAuthStats({required this.periodDays, required this.totalUsers, required this.withPassword, required this.socialOnly, required this.signupsPeriod, required this.byProvider, required this.settings});
  factory AdminAuthStats.fromJson(Map<String, dynamic> json) => AdminAuthStats(periodDays: (json['period_days'] as num?)?.toInt() ?? 30, totalUsers: (json['total_users'] as num?)?.toInt() ?? 0, withPassword: (json['with_password'] as num?)?.toInt() ?? 0, socialOnly: (json['social_only'] as num?)?.toInt() ?? 0, signupsPeriod: (json['signups_period'] as num?)?.toInt() ?? 0, byProvider: [for (final value in json['by_provider'] as List? ?? const []) Map<String, dynamic>.from(value as Map)], settings: Map<String, dynamic>.from(json['settings'] as Map? ?? const {}));
}

class AdminFeatureFlagRecord {
  final String id;
  final String module;
  final String? countryCode;
  final bool enabled;
  final int rollout;
  final String? description;
  final int eligibleUsers;
  final int enabledUsers;
  final DateTime updatedAt;

  const AdminFeatureFlagRecord({required this.id, required this.module, this.countryCode, required this.enabled, required this.rollout, this.description, required this.eligibleUsers, required this.enabledUsers, required this.updatedAt});
  factory AdminFeatureFlagRecord.fromJson(Map<String, dynamic> json) => AdminFeatureFlagRecord(id: json['id'].toString(), module: json['module'].toString(), countryCode: json['country_code']?.toString(), enabled: json['is_enabled'] == true, rollout: (json['rollout_percentage'] as num?)?.toInt() ?? 0, description: json['description']?.toString(), eligibleUsers: (json['eligible_users'] as num?)?.toInt() ?? 0, enabledUsers: (json['enabled_users'] as num?)?.toInt() ?? 0, updatedAt: p43Date(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
}

class AdminTranslationOverride {
  final String locale;
  final String key;
  final String value;
  final String? updatedByName;
  final DateTime updatedAt;
  final int total;
  const AdminTranslationOverride({required this.locale, required this.key, required this.value, this.updatedByName, required this.updatedAt, required this.total});
  factory AdminTranslationOverride.fromJson(Map<String, dynamic> json) => AdminTranslationOverride(locale: json['locale'].toString(), key: json['key'].toString(), value: json['value'].toString(), updatedByName: json['updated_by_name']?.toString(), updatedAt: p43Date(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), total: (json['total'] as num?)?.toInt() ?? 0);
}

class AdminEmailTemplate {
  final String key;
  final String locale;
  final String subject;
  final String bodyHtml;
  final String? bodyText;
  final List<String> variables;
  final bool enabled;
  final int sent30d;
  final int failed30d;
  final int queued;
  const AdminEmailTemplate({required this.key, required this.locale, required this.subject, required this.bodyHtml, this.bodyText, required this.variables, required this.enabled, required this.sent30d, required this.failed30d, required this.queued});
  factory AdminEmailTemplate.fromJson(Map<String, dynamic> json) => AdminEmailTemplate(key: json['key'].toString(), locale: json['locale'].toString(), subject: json['subject']?.toString() ?? '', bodyHtml: json['body_html']?.toString() ?? '', bodyText: json['body_text']?.toString(), variables: [for (final value in json['variables'] as List? ?? const []) value.toString()], enabled: json['is_enabled'] == true, sent30d: (json['sent_30d'] as num?)?.toInt() ?? 0, failed30d: (json['failed_30d'] as num?)?.toInt() ?? 0, queued: (json['queued'] as num?)?.toInt() ?? 0);
}

class AdminCronJob {
  final String name;
  final String schedule;
  final String command;
  final bool active;
  final String? lastStatus;
  final DateTime? lastStart;
  final String? lastMessage;
  final int runs24h;
  final int failed24h;
  const AdminCronJob({required this.name, required this.schedule, required this.command, required this.active, this.lastStatus, this.lastStart, this.lastMessage, required this.runs24h, required this.failed24h});
  factory AdminCronJob.fromJson(Map<String, dynamic> json) => AdminCronJob(name: json['jobname'].toString(), schedule: json['schedule']?.toString() ?? '', command: json['command']?.toString() ?? '', active: json['active'] == true, lastStatus: json['last_status']?.toString(), lastStart: p43Date(json['last_start']), lastMessage: json['last_message']?.toString(), runs24h: (json['runs_24h'] as num?)?.toInt() ?? 0, failed24h: (json['failed_24h'] as num?)?.toInt() ?? 0);
}

class AdminSupportTicket {
  final Map<String, dynamic> data;
  const AdminSupportTicket(this.data);
  String get id => data['id'].toString();
  String get subject => data['subject']?.toString() ?? '';
  String get status => data['status']?.toString() ?? 'open';
  String get category => data['category']?.toString() ?? 'other';
  String get slaStatus => data['sla_status']?.toString() ?? 'ok';
  int get total => (data['total'] as num?)?.toInt() ?? 0;
  factory AdminSupportTicket.fromJson(Map<String, dynamic> json) => AdminSupportTicket(json);
}