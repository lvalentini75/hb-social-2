DateTime supportDate(Object? value) => value == null ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true) : DateTime.parse(value.toString()).toUtc();

class SupportTicket {
  final String id;
  final String subject;
  final String category;
  final String status;
  final DateTime lastMessageAt;
  final String lastMessageBy;
  final int messagesCount;
  final int unreadStaffReplies;
  final DateTime createdAt;
  final DateTime? closedAt;
  const SupportTicket({required this.id, required this.subject, required this.category, required this.status, required this.lastMessageAt, required this.lastMessageBy, required this.messagesCount, required this.unreadStaffReplies, required this.createdAt, this.closedAt});
  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(id: json['id'].toString(), subject: json['subject'].toString(), category: json['category'].toString(), status: json['status'].toString(), lastMessageAt: supportDate(json['last_message_at']), lastMessageBy: json['last_message_by']?.toString() ?? 'user', messagesCount: (json['messages_count'] as num?)?.toInt() ?? 0, unreadStaffReplies: (json['unread_staff_replies'] as num?)?.toInt() ?? 0, createdAt: supportDate(json['created_at']), closedAt: json['closed_at'] == null ? null : supportDate(json['closed_at']));
}

class SupportMessage {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final bool staff;
  final bool internal;
  final String body;
  final List<Map<String, dynamic>> attachments;
  final DateTime createdAt;
  const SupportMessage({required this.id, required this.authorName, this.authorAvatarUrl, required this.staff, required this.internal, required this.body, required this.attachments, required this.createdAt});
  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(id: json['id'].toString(), authorName: json['author_name']?.toString() ?? '', authorAvatarUrl: json['author_avatar_url']?.toString(), staff: json['is_staff'] == true, internal: json['is_internal'] == true, body: json['body']?.toString() ?? '', attachments: [for (final value in json['attachments'] as List? ?? const []) Map<String, dynamic>.from(value as Map)], createdAt: supportDate(json['created_at']));
}