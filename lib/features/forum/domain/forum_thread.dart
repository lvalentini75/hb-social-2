/// A discussion thread inside the community forum, mirroring the future
/// `forum_threads` table (see ARCHITECTURE.md). Handwritten `fromJson`/
/// `toJson`/`copyWith` per AGENTS rule 9 (no code generation).
class ForumThread {
  final String id;
  final String title;
  final String? excerpt;
  final String? authorName;
  final int replyCount;
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  const ForumThread({
    required this.id,
    required this.title,
    this.excerpt,
    this.authorName,
    this.replyCount = 0,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory ForumThread.fromJson(Map<String, dynamic> json) => ForumThread(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    excerpt: json['excerpt'] as String?,
    authorName: json['author_name'] as String?,
    replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    lastActivityAt: json['last_activity_at'] != null ? DateTime.tryParse(json['last_activity_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'excerpt': excerpt,
    'author_name': authorName,
    'reply_count': replyCount,
    'created_at': createdAt.toIso8601String(),
    'last_activity_at': lastActivityAt?.toIso8601String(),
  };

  ForumThread copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? authorName,
    int? replyCount,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  }) => ForumThread(
    id: id ?? this.id,
    title: title ?? this.title,
    excerpt: excerpt ?? this.excerpt,
    authorName: authorName ?? this.authorName,
    replyCount: replyCount ?? this.replyCount,
    createdAt: createdAt ?? this.createdAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );
}
