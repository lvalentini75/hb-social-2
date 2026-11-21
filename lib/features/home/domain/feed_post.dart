import 'package:hb_social/features/feed/domain/reaction.dart' show ReactionSummary, ReactionType, ReactionTypeUi;
import 'package:hb_social/features/comments/domain/post_comment.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/reels/domain/reel.dart';
import 'package:hb_social/features/pages/articles/domain/article.dart';

class PostMedia {
  final String id;
  final String url;
  final String kind;
  final int sortOrder;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailPath;
  final String? thumbnailUrl;

  const PostMedia({required this.id, required this.url, required this.kind, required this.sortOrder, this.width, this.height, this.durationMs, this.thumbnailPath, this.thumbnailUrl});

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    id: json['id'] as String,
    url: (json['url'] ?? json['path']) as String,
    kind: json['kind'] as String,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    durationMs: (json['duration_ms'] as num?)?.toInt(),
    thumbnailPath: json['thumbnail_path'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'kind': kind, 'sort_order': sortOrder, 'width': width, 'height': height, 'duration_ms': durationMs, 'thumbnail_path': thumbnailPath, 'thumbnail_url': thumbnailUrl};
}

class FeedPost {
  final String id;
  final UserProfile author;
  final String? content;
  final String kind;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final FeedHuntingUnit? huntingUnit;
  final int reactionCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;
  final List<PostMedia> media;
  final String? myReaction;
  final String? sharedPostId;
  final FeedPost? sharedPost;
  final List<ReactionSummary> reactionSummary;
  final String? reactionDisplayName;
  final List<Comment> previewComments;
  final String countryCode;
  final bool isSensitive;
  final String visibility;
  final FeedGroup? group;
  final FeedPage? page;
  final List<FeedDog> dogs;
  final ReelVideo? reelVideo;
  final String? articleId;
  final PageArticle? article;

  const FeedPost({
    required this.id,
    required this.author,
    this.content,
    required this.kind,
    this.locationName,
    this.latitude,
    this.longitude,
    this.huntingUnit,
    required this.reactionCount,
    required this.commentCount,
    required this.shareCount,
    required this.createdAt,
    required this.media,
    this.myReaction,
    this.sharedPostId,
    this.sharedPost,
    this.reactionSummary = const [],
    this.reactionDisplayName,
    this.previewComments = const [],
    required this.countryCode,
    this.isSensitive = false,
    this.visibility = 'public',
    this.group,
    this.page,
    this.dogs = const [],
    this.reelVideo,
    this.articleId,
    this.article,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
    id: json['id'] as String,
    author: UserProfile.fromJson(Map<String, dynamic>.from(json['author'] as Map)),
    content: json['content'] as String?,
    kind: json['kind'] as String? ?? 'text',
    locationName: json['location_name'] as String?,
    latitude: (json['lat'] as num?)?.toDouble(),
    longitude: (json['lng'] as num?)?.toDouble(),
    huntingUnit: json['hunting_unit'] is Map ? FeedHuntingUnit.fromJson(Map<String, dynamic>.from(json['hunting_unit'] as Map)) : null,
    reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
    commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    media: ((json['media'] as List?) ?? const [])
        .map((item) => PostMedia.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    myReaction: json['my_reaction'] as String?,
    sharedPostId: json['shared_post_id'] as String?,
    sharedPost: json['shared'] is Map ? FeedPost.fromJson(Map<String, dynamic>.from(json['shared'] as Map)) : null,
    reactionSummary: ((json['reaction_summary'] as List?) ?? const []).map((item) => ReactionSummary(type: ReactionTypeUi.parse(item['type'] as String?) ?? ReactionType.like, count: (item['count'] as num).toInt())).toList(),
    reactionDisplayName: json['reaction_display_name'] as String?,
    previewComments: ((json['preview_comments'] as List?) ?? const []).map((item) => Comment.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
    countryCode: json['country_code'] as String? ?? 'IT',
    isSensitive: json['is_sensitive'] as bool? ?? false,
    visibility: json['visibility'] as String? ?? 'public',
    group: json['group'] is Map ? FeedGroup.fromJson(Map<String, dynamic>.from(json['group'] as Map)) : null,
    page: json['page'] is Map ? FeedPage.fromJson(Map<String, dynamic>.from(json['page'] as Map)) : null,
    dogs: [for (final item in json['dogs'] as List? ?? const []) FeedDog.fromJson(Map<String, dynamic>.from(item as Map))],
    reelVideo: json['reel_video'] is Map ? ReelVideo.fromJson(Map<String, dynamic>.from(json['reel_video'] as Map)) : null,
    articleId: json['article_id'] as String?,
    article: json['article'] is Map ? PageArticle.fromJson(Map<String, dynamic>.from(json['article'] as Map)) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author.toJson(),
    'content': content,
    'kind': kind,
    'location_name': locationName,
    'lat': latitude,
    'lng': longitude,
    'hunting_unit': huntingUnit?.toJson(),
    'reaction_count': reactionCount,
    'comment_count': commentCount,
    'share_count': shareCount,
    'created_at': createdAt.toIso8601String(),
    'media': media.map((item) => item.toJson()).toList(),
    'my_reaction': myReaction,
    'shared_post_id': sharedPostId,
    'shared': sharedPost?.toJson(),
    'reaction_summary': reactionSummary.map((item) => {'type': item.type.value, 'count': item.count}).toList(),
    'reaction_display_name': reactionDisplayName,
    'preview_comments': previewComments.map((item) => {
      'id': item.id, 'post_id': item.postId, 'parent_id': item.parentId, 'author_id': item.authorId,
      'content': item.content, 'reaction_count': item.reactionCount, 'reply_count': item.replyCount,
      'created_at': item.createdAt.toIso8601String(),
      'author': {'id': item.author.id, 'username': item.author.username, 'display_name': item.author.displayName, 'avatar_url': item.author.avatarUrl, 'verification_level': item.author.verificationLevel},
    }).toList(),
    'country_code': countryCode,
    'is_sensitive': isSensitive,
    'visibility': visibility,
    'group': group?.toJson(),
    'page': page?.toJson(),
    'dogs': dogs.map((item) => item.toJson()).toList(),
    'reel_video': reelVideo == null ? null : {'id': reelVideo!.id, 'status': reelVideo!.status, 'post_id': reelVideo!.postId, 'caption': reelVideo!.caption, 'thumbnail_url': reelVideo!.thumbnailUrl, 'duration_s': reelVideo!.durationSeconds, 'error': reelVideo!.error, 'created_at': reelVideo!.createdAt.toIso8601String(), 'submitted_at': reelVideo!.submittedAt?.toIso8601String(), 'ready_at': reelVideo!.readyAt?.toIso8601String(), 'view_count': reelVideo!.viewCount},
    'article_id': articleId,
  };

  FeedPost copyWith({String? content, bool clearContent = false, int? reactionCount, String? myReaction, bool clearReaction = false, int? commentCount, int? shareCount, List<ReactionSummary>? reactionSummary, String? reactionDisplayName, bool clearReactionDisplayName = false, List<Comment>? previewComments, List<FeedDog>? dogs}) => FeedPost(
    id: id,
    author: author,
    content: clearContent ? null : content ?? this.content,
    kind: kind,
    locationName: locationName,
    latitude: latitude,
    longitude: longitude,
    huntingUnit: huntingUnit,
    reactionCount: reactionCount ?? this.reactionCount,
    commentCount: commentCount ?? this.commentCount,
    shareCount: shareCount ?? this.shareCount,
    createdAt: createdAt,
    media: media,
    myReaction: clearReaction ? null : myReaction ?? this.myReaction,
    sharedPostId: sharedPostId,
    sharedPost: sharedPost,
    reactionSummary: reactionSummary ?? this.reactionSummary,
    reactionDisplayName: clearReactionDisplayName ? null : reactionDisplayName ?? this.reactionDisplayName,
    previewComments: previewComments ?? this.previewComments,
    countryCode: countryCode,
    isSensitive: isSensitive,
    visibility: visibility,
    group: group,
    page: page,
    dogs: dogs ?? this.dogs,
    reelVideo: reelVideo,
    articleId: articleId,
    article: article,
  );
}

class FeedDog {
  final String id;
  final String name;
  final String? avatarUrl;
  const FeedDog({required this.id, required this.name, this.avatarUrl});
  factory FeedDog.fromJson(Map<String, dynamic> json) => FeedDog(id: json['id'] as String, name: json['name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar_url': avatarUrl};
}

class FeedPage {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;
  final String verificationStatus;
  final String category;

  const FeedPage({required this.id, required this.slug, required this.name, this.avatarUrl, required this.verificationStatus, required this.category});
  bool get isVerified => verificationStatus == 'verified';
  factory FeedPage.fromJson(Map<String, dynamic> json) => FeedPage(id: json['id'] as String, slug: json['slug'].toString(), name: json['name'] as String, avatarUrl: json['avatar_url'] as String?, verificationStatus: json['verification_status'] as String? ?? 'none', category: json['category'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'name': name, 'avatar_url': avatarUrl, 'verification_status': verificationStatus, 'category': category};
}

class FeedGroup {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;

  const FeedGroup({required this.id, required this.slug, required this.name, this.avatarUrl});

  factory FeedGroup.fromJson(Map<String, dynamic> json) => FeedGroup(id: json['id'] as String, slug: json['slug'] as String, name: json['name'] as String, avatarUrl: json['avatar_url'] as String?);

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'name': name, 'avatar_url': avatarUrl};
}

class FeedHuntingUnit {
  final String id;
  final String name;

  const FeedHuntingUnit({required this.id, required this.name});

  factory FeedHuntingUnit.fromJson(Map<String, dynamic> json) => FeedHuntingUnit(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}