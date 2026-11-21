import 'package:hb_social/features/profile/domain/user_profile.dart';

class StoryTrayItem {
  final String authorId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final int storyCount;
  final int unseenCount;
  final DateTime latestAt;
  final String? latestMediaPath;
  final String latestKind;
  final String? latestThumbnailPath;

  const StoryTrayItem({required this.authorId, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, required this.storyCount, required this.unseenCount, required this.latestAt, this.latestMediaPath, required this.latestKind, this.latestThumbnailPath});

  factory StoryTrayItem.fromJson(Map<String, dynamic> json) => StoryTrayItem(
    authorId: json['author_id'] as String,
    username: json['username'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    verificationLevel: json['verification_level'] as String? ?? 'none',
    storyCount: (json['story_count'] as num?)?.toInt() ?? 0,
    unseenCount: (json['unseen_count'] as num?)?.toInt() ?? 0,
    latestAt: DateTime.parse(json['latest_at'] as String).toUtc(),
    latestMediaPath: json['latest_media_path'] as String?,
    latestKind: json['latest_kind'] as String? ?? 'image',
    latestThumbnailPath: json['latest_thumbnail_path'] as String?,
  );
}

class Story {
  final String id;
  final String authorId;
  final UserProfile author;
  final String mediaPath;
  final String mediaUrl;
  final String kind;
  final String? caption;
  final DateTime expiresAt;
  final int viewCount;
  final DateTime createdAt;
  final String? thumbnailPath;
  final String? thumbnailUrl;

  const Story({required this.id, required this.authorId, required this.author, required this.mediaPath, required this.mediaUrl, required this.kind, this.caption, required this.expiresAt, required this.viewCount, required this.createdAt, this.thumbnailPath, this.thumbnailUrl});

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    author: UserProfile.fromJson(Map<String, dynamic>.from(json['author'] as Map)),
    mediaPath: json['media_path'] as String,
    mediaUrl: json['media_url'] as String,
    kind: json['kind'] as String,
    caption: json['caption'] as String?,
    expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    thumbnailPath: json['thumbnail_path'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
  );
}

class StoryViewerData {
  final List<Story> stories;
  final Set<String> viewedStoryIds;

  const StoryViewerData({required this.stories, required this.viewedStoryIds});
}

class StoryViewerProfile {
  final DateTime viewedAt;
  final UserProfile viewer;

  const StoryViewerProfile({required this.viewedAt, required this.viewer});

  factory StoryViewerProfile.fromJson(Map<String, dynamic> json) => StoryViewerProfile(viewedAt: DateTime.parse(json['viewed_at'] as String).toUtc(), viewer: UserProfile.fromJson(Map<String, dynamic>.from(json['viewer'] as Map)));
}

class StoryHighlight {
  final String id;
  final String ownerId;
  final String title;
  final String? coverPath;
  final String? coverUrl;
  final int storyCount;
  final int sortOrder;
  final List<HighlightStory> stories;

  const StoryHighlight({required this.id, required this.ownerId, required this.title, this.coverPath, this.coverUrl, required this.storyCount, required this.sortOrder, required this.stories});
}

class HighlightStory {
  final String id;
  final String mediaPath;
  final String mediaUrl;
  final String kind;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int sortOrder;
  final String? thumbnailPath;
  final String? thumbnailUrl;

  const HighlightStory({required this.id, required this.mediaPath, required this.mediaUrl, required this.kind, this.caption, required this.createdAt, required this.expiresAt, required this.sortOrder, this.thumbnailPath, this.thumbnailUrl});

  Story toStory(UserProfile owner) => Story(id: id, authorId: owner.id, author: owner, mediaPath: mediaPath, mediaUrl: mediaUrl, kind: kind, caption: caption, expiresAt: expiresAt, viewCount: 0, createdAt: createdAt, thumbnailPath: thumbnailPath, thumbnailUrl: thumbnailUrl);
}