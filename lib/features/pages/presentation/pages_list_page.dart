import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_paged_sliver_list.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';

class PagesListPage extends ConsumerWidget {
  const PagesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(pagesViewProvider);
    final session = ref.watch(authSessionProvider).value;
    void createPage() => context.go(session == null ? AppRoutes.login : AppRoutes.pageCreate);
    return ListPageScaffold(
      title: 'nav.pages_nav'.tr(),
      subtitle: 'pages.subtitle'.tr(),
      action: MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? null : HBButton.primary(label: 'pages.create'.tr(), icon: Icons.add_rounded, onPressed: createPage),
      filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? double.infinity : 420), child: HBSegmentedTabs(labels: ['pages.discover'.tr(), 'pages.mine'.tr()], selectedIndex: view.index, onChanged: (index) => ref.read(pagesViewProvider.notifier).state = PagesView.values[index])),
        if (view == PagesView.discover) ...[const SizedBox(height: AppSpacing.md), const PageCategoryFilters()],
        if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) ...[const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'pages.create'.tr(), icon: Icons.add_rounded, onPressed: createPage))],
      ]),
      sliverBody: view == PagesView.discover ? const DiscoverPagesList() : null,
      body: view == PagesView.mine ? MyPagesList(signedIn: session != null, onCreate: createPage) : null,
    );
  }
}

class PageCategoryFilters extends ConsumerWidget {
  const PageCategoryFilters({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(pagesCategoryProvider);
    return ref.watch(pageCategoriesProvider).when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text('pages.errors.categories'.tr()),
      data: (categories) => HBFilterChipsRow(labels: ['pages.filter_all'.tr(), ...categories.map((item) => item.nameKey.tr())], selectedIndex: selected == null ? 0 : categories.indexWhere((item) => item.slug == selected) + 1, onChanged: (index) { ref.read(pagesCategoryProvider.notifier).state = index == 0 ? null : categories[index - 1].slug; ref.invalidate(pagesListProvider); }),
    );
  }
}

class DiscoverPagesList extends ConsumerWidget {
  const DiscoverPagesList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => HBPagedSliverList<CommunityPage>(
    value: ref.watch(pagesListProvider), loading: const HBListSkeleton(),
    empty: HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'pages.empty_title'.tr(), message: 'pages.empty_message'.tr())),
    error: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'pages.error_title'.tr(), message: 'pages.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pagesListProvider)))),
    onRetry: () => ref.invalidate(pagesListProvider), onLoadMore: () => ref.read(pagesListProvider.notifier).loadMore(), itemBuilder: (context, page, index) => CommunityPageListCard(page: page),
  );
}

class MyPagesList extends ConsumerWidget {
  final bool signedIn;
  final VoidCallback onCreate;
  const MyPagesList({super.key, required this.signedIn, required this.onCreate});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!signedIn) return HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'pages.sign_in_title'.tr(), message: 'pages.sign_in_message'.tr(), action: HBButton.primary(label: 'pages.sign_in_cta'.tr(), onPressed: () => context.go(AppRoutes.login))));
    return ref.watch(myPagesProvider).when(
      loading: () => const HBListSkeleton(),
      error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'pages.error_title'.tr(), message: 'pages.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myPagesProvider)))),
      data: (pages) => pages.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'pages.mine_empty_title'.tr(), message: 'pages.mine_empty_message'.tr(), action: HBButton.primary(label: 'pages.create'.tr(), onPressed: onCreate))) : Column(children: [for (var index = 0; index < pages.length; index++) ...[CommunityPageListCard(page: pages[index], showRole: true), if (index < pages.length - 1) const SizedBox(height: AppSpacing.md)]]),
    );
  }
}

class CommunityPageListCard extends StatelessWidget {
  final CommunityPage page;
  final bool showRole;
  const CommunityPageListCard({super.key, required this.page, this.showRole = false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: () => context.push(AppRoutes.pageDetailPath(page.slug)), child: HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
    HBAvatar(name: page.name, imageUrl: page.avatarUrl, size: 52), const SizedBox(width: AppSpacing.md),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Flexible(child: Text(page.name, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium)), if (page.isVerified) ...[const SizedBox(width: AppSpacing.xs), Tooltip(message: 'pages.verified_tooltip'.tr(), child: const HBBadge(kind: HBBadgeKind.verified))]]),
      const SizedBox(height: AppSpacing.xs),
      Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [HBChip(label: 'pages.category.${page.category}'.tr(), selected: false), Text('pages.follower_count'.plural(page.followerCount), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (showRole && page.myRole != null) HBChip(label: 'pages.roles.${page.myRole}'.tr(), selected: false)]),
    ])),
    const Icon(Icons.chevron_right_rounded, color: LightModeColors.lightTextTertiary),
  ])));
}