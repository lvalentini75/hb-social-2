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
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/messages/providers/conversation_providers.dart';

/// Messaggi screen: the user's conversations. No backend yet, so the list
/// always resolves empty and every state (loading, error, empty) is
/// rendered explicitly instead of any sample content.
class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(conversationsFilterProvider);
    final conversations = ref.watch(conversationsListProvider);
    final secondaryStyle = context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant);

    return ListPageScaffold(
      title: 'nav.messages'.tr(),
      action: HBButton.icon(
        icon: Icons.edit_outlined,
        onPressed: () => showComingSoonInfo(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          title: 'common.coming_soon_title'.tr(),
          message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'messages.new'.tr()}),
        ),
      ),
      filters: HBSegmentedTabs(
        labels: ['messages.filter_all'.tr(), 'messages.filter_unread'.tr(), 'messages.filter_groups'.tr()],
        selectedIndex: filter,
        onChanged: (index) => ref.read(conversationsFilterProvider.notifier).state = index,
      ),
      body: conversations.when(
        loading: () => const HBListSkeleton(showTrailing: false),
        error: (error, stackTrace) => HBCard(
          child: HBEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'messages.error_title'.tr(),
            message: 'messages.error_message'.tr(),
            action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(conversationsListProvider)),
          ),
        ),
        data: (items) => HBCard(
          child: HBEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'messages.empty_title'.tr(),
            message: 'messages.empty_message'.tr(),
            action: HBButton.primary(label: 'messages.empty_cta'.tr(), onPressed: () => context.go(AppRoutes.search)),
          ),
        ),
      ),
      rail: PageRailCard(
        label: 'messages.rail_requests_title'.tr(),
        child: Text('messages.rail_requests_empty'.tr(), style: secondaryStyle),
      ),
    );
  }
}
