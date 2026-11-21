import 'package:hb_social/features/profile/domain/user_profile.dart';

class Reel {
  final String postId;
  final DateTime createdAt;
  final String? caption;
  final bool isSensitive;
  final String? locationName;
  final String countryCode;
  final int reactionCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final String hls;
  final String? embedUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final int width;
  final int height;
  final String? myReaction;
  final bool seen;
  final UserProfile author;
  final bool isFollowing;
  final List<String> hashtags;

  const Reel({required this.postId, required this.createdAt, this.caption, required this.isSensitive, this.locationName, required this.countryCode, required this.reactionCount, required this.commentCount, required this.shareCount, required this.viewCount, required this.hls, this.embedUrl, this.thumbnailUrl, required this.durationSeconds, required this.width, required this.height, this.myReaction, required this.seen, required this.author, required this.isFollowing, required this.hashtags});

  factory Reel.fromJson(Map<String, dynamic> json) {
    final author = Map<String, dynamic>.from(json['author'] as Map? ?? const {});
    author.putIfAbsent('country_code', () => json['country_code'] ?? 'IT');
    return Reel(postId: json['post_id'].toString(), createdAt: DateTime.parse(json['created_at'].toString()).toUtc(), caption: json['caption']?.toString(), isSensitive: json['is_sensitive'] == true, locationName: json['location_name']?.toString(), countryCode: json['country_code']?.toString() ?? 'IT', reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0, commentCount: (json['comment_count'] as num?)?.toInt() ?? 0, shareCount: (json['share_count'] as num?)?.toInt() ?? 0, viewCount: (json['view_count'] as num?)?.toInt() ?? 0, hls: json['hls']?.toString() ?? '', embedUrl: json['embed_url']?.toString(), thumbnailUrl: json['thumbnail_url']?.toString(), durationSeconds: (json['duration_s'] as num?)?.round() ?? 0, width: (json['width'] as num?)?.toInt() ?? 9, height: (json['height'] as num?)?.toInt() ?? 16, myReaction: json['my_reaction']?.toString(), seen: json['seen'] == true, author: UserProfile.fromJson(author), isFollowing: author['is_following'] == true, hashtags: [for (final item in json['hashtags'] as List? ?? const []) item.toString()]);
  }

  double get aspectRatio => width > 0 && height > 0 ? width / height : 9 / 16;
}

class ReelVideo {
  final String id;
  final String status;
  final String? postId;
  final String? caption;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? error;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? readyAt;
  final int viewCount;

  const ReelVideo({required this.id, required this.status, this.postId, this.caption, this.thumbnailUrl, this.durationSeconds, this.error, required this.createdAt, this.submittedAt, this.readyAt, required this.viewCount});
  factory ReelVideo.fromJson(Map<String, dynamic> json) => ReelVideo(id: json['id'].toString(), status: json['status']?.toString() ?? 'uploading', postId: json['post_id']?.toString(), caption: json['caption']?.toString(), thumbnailUrl: json['thumbnail_url']?.toString(), durationSeconds: (json['duration_s'] as num?)?.round(), error: json['error']?.toString(), createdAt: DateTime.parse(json['created_at'].toString()).toUtc(), submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '')?.toUtc(), readyAt: DateTime.tryParse(json['ready_at']?.toString() ?? '')?.toUtc(), viewCount: (json['view_count'] as num?)?.toInt() ?? 0);
  bool get processing => status == 'uploading' || status == 'processing';
}

class ReelInsights {
  final int views;
  final int uniqueViewers;
  final int plays;
  final int completions;
  final double completionRate;
  final double averageWatchedSeconds;
  final int reactions;
  final int comments;
  final int shares;
  final List<Map<String, dynamic>> viewsByDay;
  final Map<String, int> byCountry;
  const ReelInsights({required this.views, required this.uniqueViewers, required this.plays, required this.completions, required this.completionRate, required this.averageWatchedSeconds, required this.reactions, required this.comments, required this.shares, required this.viewsByDay, required this.byCountry});
  factory ReelInsights.fromJson(Map<String, dynamic> json) => ReelInsights(views: (json['views'] as num?)?.toInt() ?? 0, uniqueViewers: (json['unique_viewers'] as num?)?.toInt() ?? 0, plays: (json['plays'] as num?)?.toInt() ?? 0, completions: (json['completions'] as num?)?.toInt() ?? 0, completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0, averageWatchedSeconds: (json['avg_watched_s'] as num?)?.toDouble() ?? 0, reactions: (json['reactions'] as num?)?.toInt() ?? 0, comments: (json['comments'] as num?)?.toInt() ?? 0, shares: (json['shares'] as num?)?.toInt() ?? 0, viewsByDay: [for (final row in json['views_by_day'] as List? ?? const []) Map<String, dynamic>.from(row as Map)], byCountry: {for (final entry in Map<String, dynamic>.from(json['by_country'] as Map? ?? const {}).entries) entry.key: (entry.value as num).toInt()});
}

class ReelUploadGrant {
  final String videoId;
  final int maxSeconds;
  final int remainingToday;
  final Map<String, dynamic> tus;
  const ReelUploadGrant({required this.videoId, required this.maxSeconds, required this.remainingToday, required this.tus});
  factory ReelUploadGrant.fromJson(Map<String, dynamic> json) => ReelUploadGrant(videoId: json['video_id'].toString(), maxSeconds: (json['max_seconds'] as num?)?.toInt() ?? 60, remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0, tus: Map<String, dynamic>.from(json['tus'] as Map));
}

class ReelUploadAllowance {
  final bool ok;
  final String? reason;
  final int maxSeconds;
  final int remainingToday;
  const ReelUploadAllowance({required this.ok, this.reason, required this.maxSeconds, required this.remainingToday});
  factory ReelUploadAllowance.fromJson(Map<String, dynamic> json) => ReelUploadAllowance(ok: json['ok'] == true, reason: json['reason']?.toString(), maxSeconds: (json['max_seconds'] as num?)?.toInt() ?? 60, remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0);
}