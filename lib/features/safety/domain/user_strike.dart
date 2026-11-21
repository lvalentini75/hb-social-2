class UserStrike {
  final String id;
  final String reason;
  final String? details;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const UserStrike({required this.id, required this.reason, this.details, required this.createdAt, this.expiresAt});

  factory UserStrike.fromJson(Map<String, dynamic> json) => UserStrike(
    id: json['id'] as String,
    reason: json['reason'] as String? ?? 'other',
    details: json['details'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String).toUtc(),
  );
}