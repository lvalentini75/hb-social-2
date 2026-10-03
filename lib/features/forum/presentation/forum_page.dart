import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/forum/providers/forum_providers.dart';

/// Forum screen: latest discussion threads. No backend yet, so the list
/// always resolves empty and every state (loading, error, empty) is
/// rendered explicitly instead of any sample content.
class ForumPage extends ConsumerWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(forumFilterProvider);
    final threads = ref.watch(forumThreadsProvider);
    final secondaryStyle = context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant);

    return ListPageScaffold(
      title: 'nav.forum'.tr(),
      action: HBButton.primary(
        label: 'forum.create'.tr(),
        icon: Icons.add_rounded,
        onPressed: () => showComingSoonInfo(
          context,
          icon: Icons.forum_outlined,
          title: 'common.coming_soon_title'.tr(),
          message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'forum.create'.tr()}),
        ),
      ),
      filters: HBFilterChipsRow(
        labels: ['forum.filter_all'.tr(), 'forum.filter_recent'.tr(), 'forum.filter_unanswered'.tr(), 'forum.filter_following'.tr()],
        selectedIndex: filter,
        onChanged: (index) => ref.read(forumFilterProvider.notifier).state = index,
      ),
      sections: [
        ListPageSection(
          title: 'forum.recent_title'.tr(),
          actionLabel: 'common.see_all'.tr(),
          onAction: () => ref.read(forumFilterProvider.notifier).state = 0,
          content: threads.when(
            loading: () => const HBListSkeleton(),
            error: (error, stackTrace) => HBCard(
              child: HBEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'forum.error_title'.tr(),
                message: 'forum.error_message'.tr(),
                action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(forumThreadsProvider)),
              ),
            ),
            data: (items) => HBCard(
              child: HBEmptyState(
                icon: Icons.forum_outlined,
                title: 'forum.empty_title'.tr(),
                message: 'forum.empty_message'.tr(),
                action: HBButton.primary(
                  label: 'forum.empty_cta'.tr(),
                  onPressed: () => showComingSoonInfo(
                    context,
                    icon: Icons.forum_outlined,
                    title: 'common.coming_soon_title'.tr(),
                    message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'forum.create'.tr()}),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      rail: Column(
        children: [
          PageRailCard(
            label: 'forum.rail_rules_title'.tr(),
            child: Text('forum.rail_rules_message'.tr(), style: secondaryStyle),
          ),
          const SizedBox(height: AppSpacing.md),
          PageRailCard(
            label: 'forum.rail_moderators_title'.tr(),
            child: Text('forum.rail_moderators_empty'.tr(), style: secondaryStyle),
          ),
        ],
      ),
    );
  }
}
