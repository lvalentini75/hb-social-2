import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';

/// Gruppi screen: a "Suggeriti per te" discovery section (filtered by the
/// Tutti/Pubblici/Privati/I miei chips) and a separate "I miei gruppi"
/// section. No backend yet, so every section always resolves empty and
/// renders its loading, error and empty states explicitly.
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  void _createGroup(BuildContext context) => showComingSoonInfo(
    context,
    icon: Icons.groups_2_outlined,
    title: 'common.coming_soon_title'.tr(),
    message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'groups.create'.tr()}),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(groupsFilterProvider);
    final suggested = ref.watch(groupsListProvider);
    final mine = ref.watch(myGroupsProvider);

    return ListPageScaffold(
      title: 'nav.groups'.tr(),
      action: HBButton.primary(label: 'groups.create'.tr(), icon: Icons.add_rounded, onPressed: () => _createGroup(context)),
      filters: HBFilterChipsRow(
        labels: ['groups.filter_all'.tr(), 'groups.filter_public'.tr(), 'groups.filter_private'.tr(), 'groups.filter_mine'.tr()],
        selectedIndex: filter,
        onChanged: (index) => ref.read(groupsFilterProvider.notifier).state = index,
      ),
      sections: [
        ListPageSection(
          title: 'groups.suggested_title'.tr(),
          actionLabel: 'common.see_all'.tr(),
          onAction: () => ref.read(groupsFilterProvider.notifier).state = 0,
          content: suggested.when(
            loading: () => const HBListSkeleton(),
            error: (error, stackTrace) => HBCard(
              child: HBEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'groups.error_title'.tr(),
                message: 'groups.error_message'.tr(),
                action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupsListProvider)),
              ),
            ),
            data: (items) => HBCard(
              child: HBEmptyState(
                icon: Icons.groups_2_outlined,
                title: 'groups.empty_title'.tr(),
                message: 'groups.empty_message'.tr(),
                action: HBButton.soft(label: 'groups.discover_cta'.tr(), onPressed: () => context.go(AppRoutes.hunting)),
              ),
            ),
          ),
        ),
        ListPageSection(
          title: 'groups.mine_title'.tr(),
          content: mine.when(
            loading: () => const HBListSkeleton(),
            error: (error, stackTrace) => HBCard(
              child: HBEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'groups.error_title'.tr(),
                message: 'groups.error_message'.tr(),
                action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myGroupsProvider)),
              ),
            ),
            data: (items) => HBCard(
              child: HBEmptyState(
                icon: Icons.group_outlined,
                title: 'groups.empty_mine_title'.tr(),
                message: 'groups.empty_mine_message'.tr(),
                action: HBButton.primary(label: 'groups.create'.tr(), onPressed: () => _createGroup(context)),
              ),
            ),
          ),
        ),
      ],
      rail: Column(
        children: [
          PageRailCard(
            label: 'groups.rail_why_title'.tr(),
            child: Text('groups.rail_why_message'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.md),
          PageRailCard(
            label: 'groups.rail_activity_title'.tr(),
            child: Text('groups.rail_activity_empty'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
