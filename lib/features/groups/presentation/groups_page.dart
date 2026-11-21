import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_paged_sliver_list.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(groupCategoryFilterProvider);
    final mine = ref.watch(groupsViewProvider);
    final session = ref.watch(authSessionProvider).value;
    final groups = ref.watch(groupsListProvider);
    final categories = ref.watch(groupCategoriesProvider).value ?? const <GroupCategory>[];
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    void createGroup() => session == null ? context.go(AppRoutes.login) : context.push('${AppRoutes.groups}/new');
    return ListPageScaffold(
      title: 'nav.groups'.tr(),
      subtitle: 'groups.subtitle'.tr(),
      action: compact ? null : HBButton.primary(label: 'groups.create'.tr(), icon: Icons.add_rounded, onPressed: createGroup),
      filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(constraints: BoxConstraints(maxWidth: compact ? double.infinity : 420), child: HBSegmentedTabs(labels: ['groups.tab_discover'.tr(), 'groups.tab_mine'.tr()], selectedIndex: mine ? 1 : 0, onChanged: (index) {
          ref.read(groupsViewProvider.notifier).state = index == 1;
          ref.invalidate(groupsListProvider);
        })),
        const SizedBox(height: AppSpacing.md),
        HBFilterChipsRow(labels: ['groups.filter_all'.tr(), ...categories.map((item) => item.nameKey.tr())], selectedIndex: selectedCategory == null ? 0 : (categories.indexWhere((item) => item.slug == selectedCategory) + 1).clamp(0, categories.length), onChanged: (index) {
          ref.read(groupCategoryFilterProvider.notifier).state = index == 0 ? null : categories[index - 1].slug;
          ref.invalidate(groupsListProvider);
        }),
        if (compact) ...[const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'groups.create'.tr(), icon: Icons.add_rounded, onPressed: createGroup))],
      ]),
      sliverBody: mine && session == null
          ? SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'groups.sign_in_title'.tr(), message: 'groups.sign_in_message'.tr(), action: HBButton.primary(label: 'groups.sign_in_cta'.tr(), onPressed: () => context.go(AppRoutes.login)))))
          : HBPagedSliverList<Group>(
              value: groups,
              loading: const HBListSkeleton(),
              empty: HBCard(child: HBEmptyState(icon: Icons.groups_2_outlined, title: (mine ? 'groups.empty_mine_title' : 'groups.empty_title').tr(), message: (mine ? 'groups.empty_mine_message' : 'groups.empty_message').tr(), action: mine ? HBButton.primary(label: 'groups.create'.tr(), icon: Icons.add_rounded, onPressed: createGroup) : null)),
              error: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'groups.error_title'.tr(), message: 'groups.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupsListProvider)))),
              onRetry: () => ref.invalidate(groupsListProvider),
              onLoadMore: () => ref.read(groupsListProvider.notifier).loadMore(),
              itemBuilder: (context, group, index) => GroupListCard(group: group),
            ),
    );
  }
}

/// PD4b group card: 100x112 cover on the left, name, real counts, up to two
/// tags, a two-line description and the membership action bottom right.
class GroupListCard extends StatelessWidget {
  final Group group;

  const GroupListCard({super.key, required this.group});

  List<String> _tags() => [
    if (group.category != null) 'groups.category.${group.category}'.tr(),
    if (group.visibility != 'public') 'groups.visibility.${group.visibility}'.tr(),
  ].take(2).toList();

  @override
  Widget build(BuildContext context) {
    final compactNumber = NumberFormat.compact(locale: context.locale.toLanguageTag());
    final tags = _tags();
    return HBCard(
      radius: AppRadius.cardWeb,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(AppRoutes.groupDetailPath(group.slug)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GroupCoverThumb(group: group),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(group.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.cardTitle.withColor(LightModeColors.text)),
          const SizedBox(height: 4),
          Text('groups.counts'.tr(namedArgs: {'members': compactNumber.format(group.memberCount), 'posts': compactNumber.format(group.postCount)}), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(LightModeColors.textSecondary)),
          if (tags.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in tags) HBChip(label: tag, tag: true)])],
          if (group.description?.trim().isNotEmpty == true) ...[const SizedBox(height: 8), Text(group.description!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: appFont(13, FontWeight.w400, height: 1.35).withColor(LightModeColors.textSecondary))],
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: GroupCardAction(group: group)),
        ])),
      ]),
    );
  }
}

class GroupCoverThumb extends StatelessWidget {
  final Group group;

  const GroupCoverThumb({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final image = group.coverUrl?.isNotEmpty == true ? group.coverUrl : group.avatarUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.media),
      child: SizedBox(
        width: 100,
        height: 112,
        child: image == null || image.isEmpty
            ? const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.groups_2_rounded, size: 28, color: LightModeColors.bosco))
            : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.groups_2_rounded, size: 28, color: LightModeColors.bosco))),
      ),
    );
  }
}

/// "Unisciti" (Bosco) / "Richiesto" (boscoSoft) / "Apri" (white, bordered).
class GroupCardAction extends StatelessWidget {
  final Group group;

  const GroupCardAction({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final pending = group.myMembership?.status == 'pending';
    final member = group.isMember;
    final label = member ? 'groups.open'.tr() : pending ? 'groups.requested'.tr() : 'groups.join'.tr();
    final background = member ? LightModeColors.surface : pending ? LightModeColors.boscoSoft : LightModeColors.bosco;
    final foreground = member || pending ? LightModeColors.bosco : Colors.white;
    return Material(
      color: background,
      shape: StadiumBorder(side: member ? const BorderSide(color: LightModeColors.border) : BorderSide.none),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => context.push(AppRoutes.groupDetailPath(group.slug)),
        child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), alignment: Alignment.center, child: Text(label, style: AppText.buttonSm.withColor(foreground))),
      ),
    );
  }
}
