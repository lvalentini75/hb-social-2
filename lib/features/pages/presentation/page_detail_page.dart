import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/features/dogs/presentation/dog_widgets.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/ads/presentation/boost_sheet.dart';
import 'package:hb_social/features/pages/articles/presentation/page_articles.dart';
import 'package:hb_social/core/services/seo_service.dart';

class CommunityPageDetailPage extends ConsumerWidget {
  final String slug;
  const CommunityPageDetailPage({super.key, required this.slug});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(pageBySlugProvider(slug)).when(
    loading: () => const PageColumns(center: HBListSkeleton(count: 3)),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'pages.error_title'.tr(), message: 'pages.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pageBySlugProvider(slug)))))),
    data: (page) => page == null ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'pages.unavailable_title'.tr(), message: 'pages.unavailable_message'.tr()))) : CommunityPageDetailBody(initialPage: page),
  );
}

class CommunityPageDetailBody extends ConsumerStatefulWidget {
  final CommunityPage initialPage;
  const CommunityPageDetailBody({super.key, required this.initialPage});
  @override
  ConsumerState<CommunityPageDetailBody> createState() => _CommunityPageDetailBodyState();
}

class _CommunityPageDetailBodyState extends ConsumerState<CommunityPageDetailBody> {
  int _tabIndex = 0;
  late CommunityPage _page = widget.initialPage;
  bool _following = false;

  Future<void> _toggleFollow() async {
    final session = ref.read(authSessionProvider).value;
    if (session == null) { context.go(AppRoutes.login); return; }
    if (_page.isFollowedByMe) {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('pages.unfollow_title'.tr()), content: Text('pages.unfollow_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'pages.unfollow'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
      if (!confirmed || !mounted) return;
    }
    final old = _page;
    setState(() { _following = true; _page = _page.copyWith(isFollowedByMe: !_page.isFollowedByMe, followerCount: (_page.followerCount + (_page.isFollowedByMe ? -1 : 1)).clamp(0, 1 << 30)); });
    try {
      if (old.isFollowedByMe) { await ref.read(pageRepositoryProvider).unfollowPage(old.id, session.user.id); } else { await ref.read(pageRepositoryProvider).followPage(old.id, session.user.id); }
      ref.invalidate(pagesListProvider); ref.invalidate(myPagesProvider);
    } on AppException catch (error) {
      if (mounted) { setState(() => _page = old); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    } finally { if (mounted) setState(() => _following = false); }
  }

  @override
  Widget build(BuildContext context) { SeoService.update(title: '${_page.name} - HB Social', description: 'seo.page_description'.tr(namedArgs: {'category': 'pages.category.${_page.category}'.tr()}), path: '/p/${_page.slug}', imageUrl: _page.coverUrl); return PageColumns(
    center: RefreshIndicator(
      onRefresh: () async { ref.invalidate(pageBySlugProvider(_page.slug)); ref.invalidate(pagePostsProvider(_page.id)); final page = await ref.read(pageBySlugProvider(_page.slug).future); if (page != null && mounted) setState(() => _page = page); },
      child: NotificationListener<ScrollNotification>(onNotification: (notification) { if (_tabIndex == 0 && notification.metrics.extentAfter < 500) ref.read(pagePostsProvider(_page.id).notifier).loadMore(); return false; }, child: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
        if (_page.status == 'archived') ...[PageArchivedBanner(page: _page), const SizedBox(height: AppSpacing.md)],
        PageHeader(page: _page, working: _following, onFollow: _toggleFollow),
        const SizedBox(height: AppSpacing.lg),
        HBSegmentedTabs(variant: HBSegmentedTabsVariant.underlined, labels: ['pages.tab_posts'.tr(), 'articles.tab'.tr(), 'pages.tab_info'.tr()], selectedIndex: _tabIndex, onChanged: (index) => setState(() => _tabIndex = index)),
        const SizedBox(height: AppSpacing.md),
        if (_tabIndex == 0) PagePosts(page: _page) else if (_tabIndex == 1) PagePublishedArticles(pageId: _page.id) else PageInfoCard(page: _page),
        if (_page.category == 'breeder') ...[const SizedBox(height: AppSpacing.md), BreederDogsSection(pageId: _page.id)],
      ]))])),
    ),
  ); }
}

class BreederDogsSection extends ConsumerWidget {
  final String pageId;
  const BreederDogsSection({super.key, required this.pageId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dogs.breeder_dogs'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), ref.watch(breederDogsProvider(pageId)).when(loading: () => const HBListSkeleton(count: 2), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'dogs.error_title'.tr(), message: 'dogs.error_message'.tr()), data: (dogs) => dogs.isEmpty ? HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.breeder_empty'.tr(), message: 'dogs.breeder_empty_message'.tr()) : DogCards(dogs: dogs, compact: true))]));
}

class PageArchivedBanner extends ConsumerWidget {
  final CommunityPage page;
  const PageArchivedBanner({super.key, required this.page});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightWarning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.archive_outlined, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('page_studio.archived'.tr(), style: context.textStyles.titleSmall)), if (page.myRole == 'owner') HBButton.soft(label: 'page_studio.reactivate'.tr(), size: HBButtonSize.sm, onPressed: () async { try { await ref.read(pageRepositoryProvider).setStatus(page.id, 'active'); ref.invalidate(pageBySlugProvider(page.slug)); ref.invalidate(myPagesProvider); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } })]));
}

class PageHeader extends StatelessWidget {
  final CommunityPage page;
  final bool working;
  final VoidCallback onFollow;
  const PageHeader({super.key, required this.page, required this.working, required this.onFollow});
  @override
  Widget build(BuildContext context) => HBCard.media(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Stack(clipBehavior: Clip.none, children: [SizedBox(height: 220, width: double.infinity, child: page.coverUrl?.isNotEmpty == true ? Image.network(page.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft)) : const ColoredBox(color: LightModeColors.lightBackgroundSoft)), Positioned(left: AppSpacing.lg, bottom: -36, child: HBAvatar(name: page.name, imageUrl: page.avatarUrl, size: 72, ringColor: Colors.white))]),
    Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 44, AppSpacing.lg, AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Flexible(child: Text(page.name, style: context.textStyles.headlineSmall?.copyWith(fontSize: 26))), if (page.isVerified) ...[const SizedBox(width: AppSpacing.xs), Tooltip(message: 'pages.verified_tooltip'.tr(), child: const HBBadge(kind: HBBadgeKind.verified))]]),
      const SizedBox(height: AppSpacing.xs),
      Text('pages.category.${page.category}'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.xs),
      Text(['pages.follower_count'.plural(page.followerCount), 'pages.post_count'.plural(page.postCount), if (page.regionName != null) page.regionName!].join(' · '), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (page.isFollowedByMe) HBButton.soft(label: 'pages.following'.tr(), icon: Icons.check_rounded, onPressed: working ? null : onFollow, isLoading: working) else HBButton.primary(label: 'pages.follow'.tr(), onPressed: working ? null : onFollow, isLoading: working), if (page.myRole != null) HBButton.secondary(label: 'pages.studio'.tr(), icon: Icons.tune_rounded, onPressed: () => context.push(AppRoutes.pageStudioPath(page.slug))), if (page.myRole != null && page.status == 'active') HBButton.soft(label: 'boost.action'.tr(), icon: Icons.rocket_launch_outlined, onPressed: () => showBoostSheet(context, targetType: 'page', targetId: page.id)), if (page.myRole != null) BoostStatusControl(targetType: 'page', targetId: page.id), if (page.myRole != null) PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) { if (value == 'event') context.push('${AppRoutes.eventCreate}?page=${page.id}'); }, itemBuilder: (_) => [PopupMenuItem(value: 'event', child: Text('events.create'.tr()))])]),
    ])),
  ]));
}

class PagePosts extends ConsumerWidget {
  final CommunityPage page;
  const PagePosts({super.key, required this.page});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(pagePostsProvider(page.id));
    return Column(children: [
      if (page.myRole != null) ...[PageComposerBar(page: page), const SizedBox(height: AppSpacing.md)],
      posts.when(loading: () => const HBListSkeleton(count: 3, showTrailing: false), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'pages.error_title'.tr(), message: 'pages.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pagePostsProvider(page.id))))), data: (value) => value.items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'pages.posts_empty_title'.tr(), message: 'pages.posts_empty_message'.tr())) : Column(children: [for (var index = 0; index < value.items.length; index++) ...[FeedPostCard(post: value.items[index]), if (index < value.items.length - 1) const SizedBox(height: AppSpacing.md)], if (value.isLoadingMore) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator())])),
    ]);
  }
}

class PageComposerBar extends StatelessWidget {
  final CommunityPage page;
  const PageComposerBar({super.key, required this.page});
  @override
  Widget build(BuildContext context) => HBCard(child: InkWell(onTap: () => showPageComposerSheet(context, pageId: page.id, pageName: page.name, pageAvatarUrl: page.avatarUrl), child: Row(children: [HBAvatar(name: page.name, imageUrl: page.avatarUrl, size: 36), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('pages.composer_hint'.tr(namedArgs: {'name': page.name}), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))), const Icon(Icons.edit_outlined, color: LightModeColors.lightPrimary)])));
}

class PageInfoCard extends StatelessWidget {
  final CommunityPage page;
  const PageInfoCard({super.key, required this.page});
  Future<void> _open(String value) async { final uri = Uri.parse(value); if (await canLaunchUrl(uri)) await launchUrl(uri); }
  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('pages.about_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), Text(page.description ?? 'common.unavailable'.tr(), style: context.textStyles.bodyMedium),
    if (page.website?.isNotEmpty == true) PageContactRow(icon: Icons.language_rounded, value: page.website!, onTap: () => _open(page.website!)),
    if (page.phone?.isNotEmpty == true) PageContactRow(icon: Icons.phone_outlined, value: page.phone!, onTap: () => _open('tel:${page.phone}')),
    if (page.email?.isNotEmpty == true) PageContactRow(icon: Icons.email_outlined, value: page.email!, onTap: () => _open('mailto:${page.email}')),
    if (page.address?.isNotEmpty == true) PageContactRow(icon: Icons.location_on_outlined, value: page.address!),
    if (page.regionName?.isNotEmpty == true) PageContactRow(icon: Icons.map_outlined, value: page.regionName!),
    PageContactRow(icon: Icons.calendar_today_outlined, value: 'pages.created_on'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.toString()).format(page.createdAt.toLocal())})),
  ]));
}

class PageContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;
  const PageContactRow({super.key, required this.icon, required this.value, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: InkWell(onTap: onTap, child: Row(children: [Icon(icon, size: 20, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: onTap == null ? null : const TextStyle(decoration: TextDecoration.underline)))])));
}
