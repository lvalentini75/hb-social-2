class PostAuthor {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final DateTime? verifiedAt;

  const PostAuthor({required this.id, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, this.verifiedAt});

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
    id: json['id'] as String? ?? '', username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?,
    verificationLevel: json['verification_level'] as String? ?? 'none',
    verifiedAt: json['verified_at'] == null ? null : DateTime.tryParse(json['verified_at'].toString())?.toUtc(),
  );

  bool get isVerified => verificationLevel != 'none';
}

class Comment {
  final String id;
  final String postId;
  final String? parentId;
  final String authorId;
  final PostAuthor author;
  final String content;
  final String? gifUrl;
  final int reactionCount;
  final int replyCount;
  final DateTime createdAt;
  final bool myLike;
  final List<Comment> replies;

  const Comment({required this.id, required this.postId, this.parentId, required this.authorId, required this.author, required this.content, this.gifUrl, required this.reactionCount, required this.replyCount, required this.createdAt, this.myLike = false, this.replies = const []});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String, postId: json['post_id'] as String? ?? '', parentId: json['parent_id'] as String?,
    authorId: json['author_id'] as String? ?? (json['author'] as Map?)?['id'] as String? ?? '',
    author: PostAuthor.fromJson(Map<String, dynamic>.from(json['author'] as Map)), content: json['content'] as String? ?? '', gifUrl: json['gif_url'] as String?,
    reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0, replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(), myLike: json['my_like'] as bool? ?? false,
    replies: ((json['replies'] as List?) ?? const []).map((item) => Comment.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
  );

  Comment copyWith({String? content, int? reactionCount, int? replyCount, bool? myLike, List<Comment>? replies}) => Comment(
    id: id, postId: postId, parentId: parentId, authorId: authorId, author: author, content: content ?? this.content, gifUrl: gifUrl,
    reactionCount: reactionCount ?? this.reactionCount, replyCount: replyCount ?? this.replyCount, createdAt: createdAt,
    myLike: myLike ?? this.myLike, replies: replies ?? this.replies,
  );
}

class CommentLikeResult {
  final bool liked;
  final int likeCount;
  const CommentLikeResult({required this.liked, required this.likeCount});
}