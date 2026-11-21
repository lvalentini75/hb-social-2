import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_colors.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

enum ReactionType { like, love, respect, wow, laugh, sad }

extension ReactionTypeUi on ReactionType {
  String get value => name;
  String get labelKey => 'reactions.types.$name';
  IconData get icon => switch (this) {
    ReactionType.like => Icons.thumb_up_rounded,
    ReactionType.love => Icons.favorite_rounded,
    ReactionType.respect => Icons.workspace_premium_rounded,
    ReactionType.wow => Icons.sentiment_very_satisfied_rounded,
    ReactionType.laugh => Icons.emoji_emotions_rounded,
    ReactionType.sad => Icons.sentiment_very_dissatisfied_rounded,
  };
  Color get color => switch (this) {
    ReactionType.like => LightModeColors.lightPrimary,
    ReactionType.love => LightModeColors.lightError,
    ReactionType.respect => LightModeColors.lightTertiary,
    ReactionType.wow => LightModeColors.lightInfo,
    ReactionType.laugh => LightModeColors.lightWarning,
    ReactionType.sad => LightModeColors.lightSecondary,
  };

  static ReactionType? parse(String? value) => ReactionType.values.where((item) => item.name == value).firstOrNull;
}

class ReactionSummary {
  final ReactionType type;
  final int count;

  const ReactionSummary({required this.type, required this.count});
}

/// Reaction data for a single post, as returned by the `reactions_summary` RPC.
class PostReactionsInfo {
  final List<ReactionSummary> summary;
  final String? myReaction;

  const PostReactionsInfo({this.summary = const [], this.myReaction});
}

class PostReaction {
  final String id;
  final ReactionType type;
  final UserProfile user;
  final DateTime createdAt;

  const PostReaction({required this.id, required this.type, required this.user, required this.createdAt});

  factory PostReaction.fromJson(Map<String, dynamic> json) => PostReaction(
    id: json['id'] as String,
    type: ReactionTypeUi.parse(json['reaction_type'] as String?) ?? ReactionType.like,
    user: UserProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );
}

class ReactionToggleResult {
  final String? myReaction;
  final int reactionCount;

  const ReactionToggleResult({this.myReaction, required this.reactionCount});
}