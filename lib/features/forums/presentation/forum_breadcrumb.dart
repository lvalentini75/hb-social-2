import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Navigation trail shared by forum and discussion pages.
class ForumBreadcrumb extends StatelessWidget {
  final String slug;
  final String forumName;
  final String? threadTitle;

  const ForumBreadcrumb({super.key, required this.slug, required this.forumName, this.threadTitle});

  @override
  Widget build(BuildContext context) {
    final linkStyle = context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightForest, fontWeight: FontWeight.w600);
    final currentStyle = context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightOnSurfaceVariant, fontWeight: FontWeight.w600);
    return Semantics(
      container: true,
      child: Row(children: [
        InkWell(borderRadius: BorderRadius.circular(AppRadius.xs), onTap: () => context.go(AppRoutes.forum), child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.forum_outlined, size: 16, color: LightModeColors.lightForest), const SizedBox(width: AppSpacing.xs), Text('nav.forum'.tr(), style: linkStyle)]))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs), child: Icon(Icons.chevron_right_rounded, size: 18, color: LightModeColors.lightTextTertiary)),
        if (threadTitle != null) ...[
          Flexible(child: InkWell(borderRadius: BorderRadius.circular(AppRadius.xs), onTap: () => context.go(AppRoutes.forumDetailPath(slug)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm), child: Text(forumName, style: linkStyle, maxLines: 1, overflow: TextOverflow.ellipsis)))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs), child: Icon(Icons.chevron_right_rounded, size: 18, color: LightModeColors.lightTextTertiary)),
        ],
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm), child: Text(threadTitle ?? forumName, style: currentStyle, maxLines: 1, overflow: TextOverflow.ellipsis))),
      ]),
    );
  }
}