class SafetyUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final DateTime actionAt;

  const SafetyUser({required this.id, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, required this.actionAt});

  factory SafetyUser.fromJson(Map<String, dynamic> json, String dateField) => SafetyUser(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    verificationLevel: json['verification_level'] as String? ?? 'none',
    actionAt: DateTime.parse(json[dateField] as String).toUtc(),
  );
}