import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/forums/domain/forum_attachment.dart';

class ForumThread {
  final String id;
  final String forumId;
  final String authorId;
  final String title;
  final String? content;
  final bool isPinned;
  final bool isLocked;
  final String? solutionReplyId;
  final int replyCount;
  final int viewCount;
  final String status;
  final String countryCode;
  final DateTime? lastReplyAt;
  final DateTime createdAt;
  final UserProfile author;
  final String? forumSlug;
  final String? forumName;
  final List<ForumAttachment> attachments;
  final List<String> tags;

  const ForumThread({required this.id, required this.forumId, required this.authorId, required this.title, this.content, required this.isPinned, required this.isLocked, this.solutionReplyId, required this.replyCount, required this.viewCount, required this.status, required this.countryCode, this.lastReplyAt, required this.createdAt, required this.author, this.forumSlug, this.forumName, this.attachments = const [], this.tags = const []});

  factory ForumThread.fromJson(Map<String, dynamic> json) => ForumThread(
    id: json['id'] as String,
    forumId: json['forum_id'] as String,
    authorId: json['author_id'] as String,
    title: json['title'] as String,
    content: json['content'] as String?,
    isPinned: json['is_pinned'] as bool? ?? false,
    isLocked: json['is_locked'] as bool? ?? false,
    solutionReplyId: json['solution_reply_id'] as String?,
    replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    status: json['status'] as String,
    countryCode: (json['country_code'] as String).trim(),
    lastReplyAt: json['last_reply_at'] == null ? null : DateTime.parse(json['last_reply_at'] as String).toUtc(),
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    author: UserProfile.fromJson(Map<String, dynamic>.from(json['author'] as Map)),
    forumSlug: (json['forum'] as Map?)?['slug'] as String?,
    forumName: (json['forum'] as Map?)?['name'] as String?,
    attachments: _attachments(json['attachments']),
    tags: _tags(json['tags']),
  );

  ForumThread copyWith({bool? isPinned, bool? isLocked, String? solutionReplyId, bool clearSolution = false, int? replyCount, int? viewCount, String? status}) => ForumThread(id: id, forumId: forumId, authorId: authorId, title: title, content: content, isPinned: isPinned ?? this.isPinned, isLocked: isLocked ?? this.isLocked, solutionReplyId: clearSolution ? null : solutionReplyId ?? this.solutionReplyId, replyCount: replyCount ?? this.replyCount, viewCount: viewCount ?? this.viewCount, status: status ?? this.status, countryCode: countryCode, lastReplyAt: lastReplyAt, createdAt: createdAt, author: author, forumSlug: forumSlug, forumName: forumName, attachments: attachments, tags: tags);
}

List<ForumAttachment> _attachments(Object? value) {
  final items = (value as List? ?? const []).map((item) => ForumAttachment.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return items;
}

List<String> _tags(Object? value) => (value as List? ?? const []).map((item) {
  if (item is String) return item;
  final map = Map<String, dynamic>.from(item as Map);
  final hashtag = map['hashtag'];
  return (hashtag is Map ? hashtag['tag'] : map['tag'])?.toString() ?? '';
}).where((tag) => tag.isNotEmpty).toList();