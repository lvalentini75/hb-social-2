/// A direct/group conversation, mirroring the future `conversations` table
/// (see ARCHITECTURE.md). Handwritten `fromJson`/`toJson`/`copyWith` per
/// AGENTS rule 9 (no code generation). There is no separate `Message` model
/// yet: this list screen only needs the conversation summary.
class Conversation {
  final String id;
  final String participantName;
  final String? participantAvatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroup;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.participantName,
    this.participantAvatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroup = false,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    participantName: json['participant_name'] as String? ?? '',
    participantAvatarUrl: json['participant_avatar_url'] as String?,
    lastMessagePreview: json['last_message_preview'] as String?,
    lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at'] as String) : null,
    unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    isGroup: json['is_group'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant_name': participantName,
    'participant_avatar_url': participantAvatarUrl,
    'last_message_preview': lastMessagePreview,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'unread_count': unreadCount,
    'is_group': isGroup,
    'created_at': createdAt.toIso8601String(),
  };

  Conversation copyWith({
    String? id,
    String? participantName,
    String? participantAvatarUrl,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isGroup,
    DateTime? createdAt,
  }) => Conversation(
    id: id ?? this.id,
    participantName: participantName ?? this.participantName,
    participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    isGroup: isGroup ?? this.isGroup,
    createdAt: createdAt ?? this.createdAt,
  );
}
