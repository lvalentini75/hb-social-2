import 'package:hb_social/features/home/domain/feed_post.dart';

class ScheduledPost {
  final FeedPost post;
  final DateTime scheduledAt;

  const ScheduledPost({required this.post, required this.scheduledAt});

  factory ScheduledPost.fromJson(Map<String, dynamic> json) => ScheduledPost(
    post: FeedPost.fromJson(json),
    scheduledAt: DateTime.parse(json['scheduled_at'].toString()).toUtc(),
  );
}