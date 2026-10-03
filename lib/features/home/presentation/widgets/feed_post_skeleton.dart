import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';

/// Loading placeholder for a single feed post: avatar + two header lines,
/// two text lines and a media block, all rendered with [HBSkeleton].
class FeedPostSkeleton extends StatelessWidget {
  const FeedPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HBSkeleton(height: 40, width: 40, radius: AppRadius.pill),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    HBSkeleton(height: 12, width: 140),
                    SizedBox(height: AppSpacing.xs),
                    HBSkeleton(height: 10, width: 90),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const HBSkeleton(height: 12),
          const SizedBox(height: AppSpacing.sm),
          const HBSkeleton(height: 12, width: 220),
          const SizedBox(height: AppSpacing.md),
          const HBSkeleton(height: 160, radius: AppRadius.sm),
        ],
      ),
    );
  }
}
