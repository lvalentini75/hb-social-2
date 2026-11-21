import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';

class ForumsPage extends ConsumerWidget {
  const ForumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(forumsTabProvider);
    final mobile = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg), sliver: SliverList.list(children: [
      HBPageHeader(title: 'forums.title'.tr(), subtitle: 'forums.subtitle'.tr(), action: mobile ? null : HBButton.primary(label: 'forums.create'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.forumCreate))),
      const SizedBox(height: AppSpacing.md),
      ConstrainedBox(constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 420), child: HBSegmentedTabs(labels: ['forums.tabs.forums'.tr(), 'forums.tabs.recent'.tr(), 'forums.tabs.mine'.tr()], selectedIndex: ForumsTab.values.indexOf(tab), onChanged: (index) => ref.read(forumsTabProvider.notifier).state = ForumsTab.values[index])),
      const SizedBox(height: AppSpacing.md),
      if (mobile) ...[SizedBox(width: double.infinity, child: HBButton.primary(label: 'forums.create'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.forumCreate))), const SizedBox(height: AppSpacing.md)],
      if (tab != ForumsTab.recent) const ForumCategoryFilters(),
      if (tab != ForumsTab.recent) const SizedBox(height: AppSpacing.md),
      if (tab == ForumsTab.recent) const RecentThreadsToolbar(),
      if (tab == ForumsTab.recent) const SizedBox(height: AppSpacing.md),
      if (tab == ForumsTab.recent) const RecentThreadsList() else const ForumsList(),
    ]))]));
  }
}

class RecentThreadsToolbar extends ConsumerWidget {
  const RecentThreadsToolbar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(recentThreadQueryProvider);
    return Row(children: [if (query.tag != null) InputChip(label: Text('#${query.tag}'), onDeleted: () => ref.read(recentThreadQueryProvider.notifier).state = query.copyWith(clearTag: true)), const Spacer(), PopupMenuButton<String>(initialValue: query.sort, onSelected: (sort) => ref.read(recentThreadQueryProvider.notifier).state = query.copyWith(sort: sort), itemBuilder: (_) => [for (final sort in const ['activity', 'views', 'replies', 'newest']) PopupMenuItem(value: sort, child: Text('forum_advanced.sort.$sort'.tr()))])]);
  }
}

class ForumCategoryFilters extends ConsumerWidget {
  const ForumCategoryFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(forumCategoriesProvider).maybeWhen(data: (categories) {
    final selected = ref.watch(forumCategoryFilterProvider);
    final labels = ['forums.filter_all'.tr(), ...categories.map((item) => item.nameKey.tr())];
    final index = selected == null ? 0 : categories.indexWhere((item) => item.slug == selected) + 1;
    return HBFilterChipsRow(labels: labels, selectedIndex: index.clamp(0, labels.length - 1), onChanged: (value) => ref.read(forumCategoryFilterProvider.notifier).state = value == 0 ? null : categories[value - 1].slug);
  }, orElse: () => const SizedBox.shrink());
}

class ForumsList extends ConsumerWidget {
  const ForumsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(forumsTabProvider) == ForumsTab.mine;
    if (mine && ref.watch(authSessionProvider).value == null) return HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'forums.sign_in_title'.tr(), message: 'forums.sign_in_message'.tr(), action: HBButton.primary(label: 'forums.sign_in_cta'.tr(), onPressed: () => context.go(AppRoutes.login))));
    return ref.watch(forumsProvider).when(
      loading: () => const HBListSkeleton(),
      error: (_, __) => ForumLoadError(onRetry: () => ref.invalidate(forumsProvider)),
      data: (page) => page.items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: (mine ? 'forums.mine_empty_title' : 'forums.empty_title').tr(), message: (mine ? 'forums.mine_empty_message' : 'forums.empty_message').tr())) : Column(children: [for (var index = 0; index < page.items.length; index++) ...[ForumCard(forum: page.items[index]), if (index < page.items.length - 1) const SizedBox(height: AppSpacing.md)], if (page.hasMore) ...[const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'feed.load_more'.tr(), onPressed: page.isLoadingMore ? null : () => ref.read(forumsProvider.notifier).loadMore())]]),
    );
  }
}

class RecentThreadsList extends ConsumerWidget {
  const RecentThreadsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(recentThreadsProvider).when(
    loading: () => const HBListSkeleton(),
    error: (_, __) => ForumLoadError(onRetry: () => ref.invalidate(recentThreadsProvider)),
    data: (page) => page.items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'forums.recent_empty_title'.tr(), message: 'forums.recent_empty_message'.tr())) : Column(children: [for (var index = 0; index < page.items.length; index++) ...[RecentThreadCard(thread: page.items[index]), if (index < page.items.length - 1) const SizedBox(height: AppSpacing.md)], if (page.hasMore) ...[const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'feed.load_more'.tr(), onPressed: page.isLoadingMore ? null : () => ref.read(recentThreadsProvider.notifier).loadMore())]]),
  );
}

class ForumCard extends StatelessWidget {
  final Forum forum;
  const ForumCard({super.key, required this.forum});

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: () => context.push(AppRoutes.forumDetailPath(forum.slug)), child: HBCard.media(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(aspectRatio: 5, child: forum.coverUrl?.isNotEmpty == true ? Image.network(forum.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft)) : const ColoredBox(color: LightModeColors.lightBackgroundSoft)),
    Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HBAvatar(name: forum.name, imageUrl: forum.avatarUrl, size: 48),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(forum.name, style: context.textStyles.titleMedium)), if (forum.isPrivate) const Icon(Icons.lock_outline_rounded, size: 18)]), if (forum.description?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.xs), Text(forum.description!, maxLines: 2, overflow: TextOverflow.ellipsis)], const SizedBox(height: AppSpacing.sm), Row(children: [Expanded(child: Text('${'forums.thread_count'.plural(forum.threadCount)} · ${'forums.member_count'.plural(forum.memberCount)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), if (forum.category != null) HBChip(label: 'forums.category.${forum.category}'.tr(), selected: false)])])),
    ])),
  ])));
}

class RecentThreadCard extends StatelessWidget {
  final ForumThread thread;
  const RecentThreadCard({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final activity = thread.lastReplyAt ?? thread.createdAt;
    return GestureDetector(onTap: thread.forumSlug == null ? null : () => context.push(AppRoutes.threadPath(thread.forumSlug!, thread.id)), child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(thread.title, style: context.textStyles.titleMedium)), if (DateTime.now().difference(thread.createdAt) < const Duration(hours: 24)) HBStatusChip(kind: HBStatusKind.info, label: 'forum_advanced.new_badge'.tr())]),
      if (thread.tags.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, children: [for (final tag in thread.tags.take(3)) HBChip(label: '#$tag', selected: false, onTap: () => context.push(AppRoutes.forumTagPath(tag))), if (thread.tags.length > 3) HBChip(label: '+${thread.tags.length - 3}', selected: false)])],
      const SizedBox(height: AppSpacing.xs),
      Text('forums.in_forum'.tr(namedArgs: {'forum': thread.forumName ?? ''}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightPrimary)),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [HBAvatar(name: thread.author.displayName, imageUrl: thread.author.avatarUrl, size: 24), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(thread.author.displayName, overflow: TextOverflow.ellipsis)), if (thread.solutionReplyId != null) HBStatusChip(kind: HBStatusKind.approved, label: 'forums.solved'.tr()), if (thread.isPinned) ...[const SizedBox(width: AppSpacing.xs), HBStatusChip(kind: HBStatusKind.info, label: 'forums.pinned'.tr())], if (thread.isLocked) ...[const SizedBox(width: AppSpacing.xs), HBStatusChip(kind: HBStatusKind.neutral, label: 'forums.closed'.tr())]]),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [if (thread.attachments.isNotEmpty) ...[const Icon(Icons.attach_file_rounded, size: 16), Text('${thread.attachments.length}'), const SizedBox(width: AppSpacing.xs)], Expanded(child: Text('forums.recent_meta'.tr(namedArgs: {'replies': '${thread.replyCount}', 'time': relativeTime(context, activity)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)))]),
    ])));
  }
}

class ForumLoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const ForumLoadError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'forums.error_title'.tr(), message: 'forums.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)));
}