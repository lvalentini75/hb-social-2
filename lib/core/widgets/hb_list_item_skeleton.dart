import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';

/// Loading placeholder for a single row in a list page (groups, forum,
/// pages, messages, notifications): a square avatar skeleton, two text
/// lines and an optional trailing action skeleton.
class HBListItemSkeleton extends StatelessWidget {
  final bool showTrailing;

  const HBListItemSkeleton({super.key, this.showTrailing = true});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const HBSkeleton(height: 48, width: 48, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                HBSkeleton(height: 13, width: 160),
                SizedBox(height: AppSpacing.xs),
                HBSkeleton(height: 11, width: 100),
              ],
            ),
          ),
          if (showTrailing) ...[const SizedBox(width: AppSpacing.md), const HBSkeleton(height: 32, width: 84, radius: AppRadius.sm)],
        ],
      ),
    );
  }
}

/// A column of [count] [HBListItemSkeleton] rows with consistent spacing.
class HBListSkeleton extends StatelessWidget {
  final int count;
  final bool showTrailing;

  const HBListSkeleton({super.key, this.count = 3, this.showTrailing = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          HBListItemSkeleton(showTrailing: showTrailing),
        ],
      ],
    );
  }
}
