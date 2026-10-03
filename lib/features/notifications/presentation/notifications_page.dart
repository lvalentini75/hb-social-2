import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';

/// Notifiche screen: all notifications, mentions or requests. No backend
/// yet, so the list always resolves empty and every state (loading, error,
/// empty) is rendered explicitly instead of any sample content.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(notificationsTabProvider);
    final notifications = ref.watch(notificationsListProvider);

    return ListPageScaffold(
      title: 'nav.notifications'.tr(),
      action: HBButton.ghost(
        label: 'notifications.mark_all_read'.tr(),
        size: HBButtonSize.sm,
        onPressed: () => showComingSoonInfo(
          context,
          icon: Icons.done_all_rounded,
          title: 'common.coming_soon_title'.tr(),
          message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'notifications.mark_all_read'.tr()}),
        ),
      ),
      filters: HBSegmentedTabs(
        labels: ['notifications.tab_all'.tr(), 'notifications.tab_mentions'.tr(), 'notifications.tab_requests'.tr()],
        selectedIndex: NotificationsTab.values.indexOf(tab),
        onChanged: (index) => ref.read(notificationsTabProvider.notifier).state = NotificationsTab.values[index],
      ),
      body: notifications.when(
        loading: () => const HBListSkeleton(showTrailing: false),
        error: (error, stackTrace) => HBCard(
          child: HBEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'notifications.error_title'.tr(),
            message: 'notifications.error_message'.tr(),
            action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(notificationsListProvider)),
          ),
        ),
        data: (items) => HBCard(
          child: HBEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'notifications.empty_title'.tr(),
            message: 'notifications.empty_message'.tr(),
          ),
        ),
      ),
      rail: PageRailCard(
        label: 'notifications.rail_settings_title'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'notifications.rail_settings_message'.tr(),
              style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            HBButton.soft(
              label: 'notifications.rail_settings_cta'.tr(),
              size: HBButtonSize.sm,
              onPressed: () => showComingSoonInfo(
                context,
                icon: Icons.tune_rounded,
                title: 'common.coming_soon_title'.tr(),
                message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'notifications.rail_settings_cta'.tr()}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
