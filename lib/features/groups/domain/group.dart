/// A hunting group / community, mirroring the future `groups` table
/// (see ARCHITECTURE.md, community domain). Handwritten `fromJson`/`toJson`
/// per AGENTS rule 9 (no code generation).
class Group {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String? countryCode;
  final int memberCount;
  final bool isMember;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Group({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    this.countryCode,
    this.memberCount = 0,
    this.isMember = false,
    this.isPublic = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    countryCode: json['country_code'] as String?,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    isMember: json['is_member'] as bool? ?? false,
    isPublic: json['is_public'] as bool? ?? true,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'country_code': countryCode,
    'member_count': memberCount,
    'is_member': isMember,
    'is_public': isPublic,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? countryCode,
    int? memberCount,
    bool? isMember,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Group(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    countryCode: countryCode ?? this.countryCode,
    memberCount: memberCount ?? this.memberCount,
    isMember: isMember ?? this.isMember,
    isPublic: isPublic ?? this.isPublic,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
