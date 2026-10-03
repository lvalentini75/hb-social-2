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
import 'package:hb_social/features/pages/providers/page_providers.dart';

/// Pagine screen: community/business pages to discover and follow. No
/// backend yet, so the list always resolves empty and every state (loading,
/// error, empty) is rendered explicitly instead of any sample content.
///
/// Named `PagesListPage` (not `PagesPage`) to keep the file's public API
/// unambiguous next to Flutter's own `Page` class used by the domain model.
class PagesListPage extends ConsumerWidget {
  const PagesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(pagesFilterProvider);
    final pages = ref.watch(pagesListProvider);
    final secondaryStyle = context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant);

    void createPage() => showComingSoonInfo(
      context,
      icon: Icons.article_outlined,
      title: 'common.coming_soon_title'.tr(),
      message: 'common.coming_soon_message'.tr(namedArgs: {'section': 'pages.create'.tr()}),
    );

    return ListPageScaffold(
      title: 'nav.pages'.tr(),
      action: HBButton.primary(
        label: 'pages.create'.tr(),
        icon: Icons.add_rounded,
        onPressed: createPage,
      ),
      filters: HBFilterChipsRow(
        labels: ['pages.filter_all'.tr(), 'pages.filter_associations'.tr(), 'pages.filter_businesses'.tr(), 'pages.filter_institutions'.tr()],
        selectedIndex: filter,
        onChanged: (index) => ref.read(pagesFilterProvider.notifier).state = index,
      ),
      sections: [
        ListPageSection(
          title: 'pages.suggested_title'.tr(),
          actionLabel: 'common.see_all'.tr(),
          onAction: () => ref.read(pagesFilterProvider.notifier).state = 0,
          content: pages.when(
            loading: () => const HBListSkeleton(),
            error: (error, stackTrace) => HBCard(
              child: HBEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'pages.error_title'.tr(),
                message: 'pages.error_message'.tr(),
                action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pagesListProvider)),
              ),
            ),
            data: (items) => HBCard(
              child: HBEmptyState(
                icon: Icons.article_outlined,
                title: 'pages.empty_title'.tr(),
                message: 'pages.empty_message'.tr(),
                action: HBButton.primary(label: 'pages.empty_cta'.tr(), onPressed: createPage),
              ),
            ),
          ),
        ),
      ],
      rail: Column(
        children: [
          PageRailCard(
            label: 'pages.rail_create_title'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('pages.rail_create_message'.tr(), style: secondaryStyle),
                const SizedBox(height: AppSpacing.sm),
                HBButton.soft(label: 'pages.create'.tr(), size: HBButtonSize.sm, onPressed: createPage),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PageRailCard(
            label: 'pages.rail_verification_title'.tr(),
            child: Text('pages.rail_verification_message'.tr(), style: secondaryStyle),
          ),
        ],
      ),
    );
  }
}
