enum BadgeType { hunter, gunShop, guide, association, page }

extension BadgeTypeValue on BadgeType {
  String get code => switch (this) {BadgeType.hunter => 'hunter', BadgeType.gunShop => 'gun_shop', BadgeType.guide => 'guide', BadgeType.association => 'association', BadgeType.page => 'page'};
  String get translationKey => 'verification.badge.$code';
  static BadgeType parse(Object? value) => BadgeType.values.firstWhere((item) => item.code == value, orElse: () => BadgeType.hunter);
}

enum DocumentKind { licenceFront, licenceBack, idDocument, vatCertificate, chamberRegistration, associationStatute, guideLicence, other }

extension DocumentKindValue on DocumentKind {
  String get code => switch (this) {DocumentKind.licenceFront => 'licence_front', DocumentKind.licenceBack => 'licence_back', DocumentKind.idDocument => 'id_document', DocumentKind.vatCertificate => 'vat_certificate', DocumentKind.chamberRegistration => 'chamber_registration', DocumentKind.associationStatute => 'association_statute', DocumentKind.guideLicence => 'guide_licence', DocumentKind.other => 'other'};
  String get translationKey => 'verification.doc.$code';
  static DocumentKind parse(Object? value) => DocumentKind.values.firstWhere((item) => item.code == value, orElse: () => DocumentKind.other);
}

class VerificationDocument {
  final String path;
  final DocumentKind kind;
  final String name;
  final int size;

  const VerificationDocument({required this.path, required this.kind, required this.name, required this.size});
  factory VerificationDocument.fromJson(Map<String, dynamic> json) => VerificationDocument(path: json['path'] as String? ?? '', kind: DocumentKindValue.parse(json['kind']), name: json['name'] as String? ?? '', size: (json['size'] as num?)?.toInt() ?? 0);
  Map<String, dynamic> toJson() => {'path': path, 'kind': kind.code, 'name': name, 'size': size};
}

enum VerificationRequestStatus { pending, approved, rejected, cancelled, expired }

extension VerificationRequestStatusValue on VerificationRequestStatus {
  String get code => name;
  static VerificationRequestStatus parse(Object? value) => VerificationRequestStatus.values.firstWhere((item) => item.name == value, orElse: () => VerificationRequestStatus.pending);
}

class VerificationRequest {
  final String id;
  final BadgeType badgeType;
  final VerificationRequestStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final String? pageId;
  final String? pageName;
  final List<VerificationDocument> documents;
  final DateTime? documentsPurgedAt;

  const VerificationRequest({required this.id, required this.badgeType, required this.status, required this.createdAt, this.reviewedAt, this.rejectionReason, this.expiresAt, this.pageId, this.pageName, this.documents = const [], this.documentsPurgedAt});
  factory VerificationRequest.fromJson(Map<String, dynamic> json) => VerificationRequest(
    id: json['id'] as String? ?? '', badgeType: BadgeTypeValue.parse(json['badge_type']), status: VerificationRequestStatusValue.parse(json['status']), createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), reviewedAt: _date(json['reviewed_at']), rejectionReason: json['rejection_reason'] as String?, expiresAt: _date(json['expires_at']), pageId: json['page_id'] as String?, pageName: json['page_name'] as String?, documents: _documents(json['documents']), documentsPurgedAt: _date(json['documents_purged_at']));
}

class VerificationStatus {
  final BadgeType? level;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final int? daysLeft;
  final bool renewable;
  final VerificationRequest? pending;
  final List<VerificationRequest> history;

  const VerificationStatus({this.level, this.verifiedAt, this.expiresAt, this.daysLeft, this.renewable = false, this.pending, this.history = const []});
  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    final levelCode = json['level']?.toString();
    final pending = json['pending'];
    return VerificationStatus(level: levelCode == null || levelCode == 'none' ? null : BadgeTypeValue.parse(levelCode), verifiedAt: _date(json['verified_at']), expiresAt: _date(json['expires_at']), daysLeft: (json['days_left'] as num?)?.toInt(), renewable: json['renewable'] as bool? ?? false, pending: pending is Map ? VerificationRequest.fromJson({...Map<String, dynamic>.from(pending), 'status': 'pending'}) : null, history: (json['history'] as List? ?? const []).whereType<Map>().map((item) => VerificationRequest.fromJson(Map<String, dynamic>.from(item))).toList());
  }
}

DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
List<VerificationDocument> _documents(Object? value) => (value as List? ?? const []).whereType<Map>().map((item) => VerificationDocument.fromJson(Map<String, dynamic>.from(item))).toList();