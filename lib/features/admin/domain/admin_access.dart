class AdminAccess {
  final String userId;
  final String roleName;
  final String? roleDescription;
  final bool mfaEnabled;
  final Map<String, String> permissions;

  const AdminAccess({required this.userId, required this.roleName, this.roleDescription, required this.mfaEnabled, required this.permissions});

  factory AdminAccess.fromJson(Map<String, dynamic> json, Map<String, String> permissions) {
    final role = json['role'] as Map<String, dynamic>? ?? const {};
    return AdminAccess(
      userId: json['user_id'] as String,
      roleName: role['name'] as String? ?? '',
      roleDescription: role['description'] as String?,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      permissions: Map.unmodifiable(permissions),
    );
  }

  bool canRead(String module) => permissions[module] == 'read' || permissions[module] == 'write';
  bool canWrite(String module) => permissions[module] == 'write';
}