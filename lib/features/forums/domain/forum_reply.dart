import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/forums/domain/forum_attachment.dart';

class ForumReply {
  final String id;
  final String threadId;
  final String authorId;
  final String? parentId;
  final String content;
  final int reactionCount;
  final String status;
  final DateTime createdAt;
  final UserProfile author;
  final int depth;
  final List<ForumAttachment> attachments;
  final bool myLike;

  const ForumReply({required this.id, required this.threadId, required this.authorId, this.parentId, required this.content, required this.reactionCount, required this.status, required this.createdAt, required this.author, this.depth = 0, this.attachments = const [], this.myLike = false});

  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
    id: json['id'] as String,
    threadId: json['thread_id'] as String,
    authorId: json['author_id'] as String,
    parentId: json['parent_id'] as String?,
    content: json['content'] as String,
    reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    author: UserProfile.fromJson(Map<String, dynamic>.from(json['author'] as Map)),
    depth: (json['depth'] as num?)?.toInt() ?? 0,
    attachments: ((json['attachments'] as List?) ?? const []).map((item) => ForumAttachment.fromJson(Map<String, dynamic>.from(item as Map))).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    myLike: json['my_like'] as bool? ?? false,
  );

  ForumReply copyWith({String? content, int? depth, int? reactionCount, String? status, bool? myLike}) => ForumReply(id: id, threadId: threadId, authorId: authorId, parentId: parentId, content: content ?? this.content, reactionCount: reactionCount ?? this.reactionCount, status: status ?? this.status, createdAt: createdAt, author: author, depth: depth ?? this.depth, attachments: attachments, myLike: myLike ?? this.myLike);
}