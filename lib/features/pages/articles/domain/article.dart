class ArticleIdentity {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;
  final String verificationStatus;

  const ArticleIdentity({required this.id, required this.slug, required this.name, this.avatarUrl, required this.verificationStatus});
  factory ArticleIdentity.fromJson(Map<String, dynamic> json) => ArticleIdentity(id: json['id'].toString(), slug: json['slug'].toString(), name: json['name']?.toString() ?? '', avatarUrl: json['avatar_url'] as String?, verificationStatus: json['verification_status']?.toString() ?? 'none');
}

class ArticleAuthor {
  final String id;
  final String displayName;
  final String username;

  const ArticleAuthor({required this.id, required this.displayName, required this.username});
  factory ArticleAuthor.fromJson(Map<String, dynamic> json) => ArticleAuthor(id: json['id'].toString(), displayName: json['display_name']?.toString() ?? '', username: json['username']?.toString() ?? '');
}

class PageArticle {
  final String id;
  final String pageId;
  final String slug;
  final String title;
  final String? subtitle;
  final String? coverPath;
  final String? coverUrl;
  final String? body;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final String? postId;
  final int readingTimeMin;
  final int viewCount;
  final int reactionCount;
  final int commentCount;
  final int shareCount;
  final String? myReaction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ArticleIdentity page;
  final ArticleAuthor author;
  final bool canEdit;

  const PageArticle({required this.id, required this.pageId, required this.slug, required this.title, this.subtitle, this.coverPath, this.coverUrl, this.body, required this.status, this.scheduledAt, this.publishedAt, this.postId, required this.readingTimeMin, required this.viewCount, required this.reactionCount, required this.commentCount, required this.shareCount, this.myReaction, required this.createdAt, required this.updatedAt, required this.page, required this.author, required this.canEdit});

  factory PageArticle.fromJson(Map<String, dynamic> json) {
    final post = json['post'] is Map ? Map<String, dynamic>.from(json['post'] as Map) : const <String, dynamic>{};
    return PageArticle(
      id: json['id'].toString(), pageId: json['page_id'].toString(), slug: json['slug'].toString(), title: json['title']?.toString() ?? '', subtitle: json['subtitle'] as String?, coverPath: json['cover_path'] as String?, coverUrl: json['cover_url'] as String?, body: json['body'] as String?, status: json['status']?.toString() ?? 'draft',
      scheduledAt: _date(json['scheduled_at']), publishedAt: _date(json['published_at']), postId: json['post_id']?.toString(), readingTimeMin: (json['reading_time_min'] as num?)?.toInt() ?? 1, viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      reactionCount: (post['reaction_count'] as num?)?.toInt() ?? 0, commentCount: (post['comment_count'] as num?)?.toInt() ?? 0, shareCount: (post['share_count'] as num?)?.toInt() ?? 0, myReaction: post['my_reaction'] as String?,
      createdAt: _date(json['created_at'])!, updatedAt: _date(json['updated_at'])!, page: ArticleIdentity.fromJson(Map<String, dynamic>.from(json['page'] as Map)), author: ArticleAuthor.fromJson(Map<String, dynamic>.from(json['author'] as Map)), canEdit: json['can_edit'] as bool? ?? false,
    );
  }
}

DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();