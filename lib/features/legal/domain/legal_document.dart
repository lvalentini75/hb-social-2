class LegalDocument {
  final String id;
  final String kind;
  final int version;
  final String locale;
  final String title;
  final String? summary;
  final String bodyMarkdown;
  final DateTime? publishedAt;

  const LegalDocument({required this.id, required this.kind, required this.version, required this.locale, required this.title, this.summary, required this.bodyMarkdown, this.publishedAt});
  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(id: json['id']?.toString() ?? '', kind: json['kind']?.toString() ?? '', version: (json['version'] as num?)?.toInt() ?? 0, locale: json['locale']?.toString() ?? 'it', title: json['title']?.toString() ?? '', summary: json['summary']?.toString(), bodyMarkdown: json['body_md']?.toString() ?? '', publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? '')?.toUtc());
}

class PendingLegalConsent {
  final String kind;
  final int version;
  final String title;
  final String? summary;
  final bool firstTime;
  const PendingLegalConsent({required this.kind, required this.version, required this.title, this.summary, required this.firstTime});
  factory PendingLegalConsent.fromJson(Map<String, dynamic> json) => PendingLegalConsent(kind: json['kind']?.toString() ?? '', version: (json['version'] as num?)?.toInt() ?? 0, title: json['title']?.toString() ?? '', summary: json['summary']?.toString(), firstTime: json['first_time'] == true);
}

class PendingLegalConsents {
  final List<PendingLegalConsent> pending;
  final bool ageConfirmed;
  final int minAge;
  const PendingLegalConsents({required this.pending, required this.ageConfirmed, required this.minAge});
  factory PendingLegalConsents.fromJson(Map<String, dynamic> json) => PendingLegalConsents(pending: [for (final item in json['pending'] as List? ?? const []) PendingLegalConsent.fromJson(Map<String, dynamic>.from(item as Map))], ageConfirmed: json['age_confirmed'] == true, minAge: (json['min_age'] as num?)?.toInt() ?? 18);
}

class LegalConsentRecord {
  final String kind;
  final int version;
  final String platform;
  final DateTime? acceptedAt;
  const LegalConsentRecord({required this.kind, required this.version, required this.platform, this.acceptedAt});
  factory LegalConsentRecord.fromJson(Map<String, dynamic> json) => LegalConsentRecord(kind: json['kind']?.toString() ?? '', version: (json['version'] as num?)?.toInt() ?? 0, platform: json['platform']?.toString() ?? '', acceptedAt: DateTime.tryParse(json['accepted_at']?.toString() ?? '')?.toUtc());
}