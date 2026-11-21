import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/features/pages/articles/domain/article.dart';
import 'package:hb_social/features/pages/articles/providers/articles_providers.dart';

class PageArticlesManager extends ConsumerStatefulWidget {
  final String pageId;
  final String pageSlug;
  const PageArticlesManager({super.key, required this.pageId, required this.pageSlug});
  @override ConsumerState<PageArticlesManager> createState() => _PageArticlesManagerState();
}

class _PageArticlesManagerState extends ConsumerState<PageArticlesManager> {
  String status = 'all';
  @override Widget build(BuildContext context) {
    final request = (pageId: widget.pageId, status: status);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in const ['all', 'published', 'draft', 'scheduled', 'archived']) HBChip(label: 'articles.status.$value'.tr(), selected: status == value, onTap: () => setState(() => status = value))]),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: 'posts.scheduled.title'.tr(), icon: Icons.schedule_outlined, onPressed: () => context.push(AppRoutes.scheduledPostsPath(pageId: widget.pageId))), HBButton.primary(label: 'articles.manager.new'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.articleNewPath(widget.pageSlug)))]),
      ]),
      const SizedBox(height: AppSpacing.md),
      ref.watch(articlesByPageProvider(request)).when(
        loading: () => const HBListSkeleton(count: 4),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'articles.errors.load_title'.tr(), message: 'articles.errors.load_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(articlesByPageProvider(request)))),
        data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.article_outlined, title: 'articles.manager.empty_title'.tr(), message: 'articles.manager.empty_message'.tr()) : Column(children: [for (var index = 0; index < items.length; index++) ...[ArticleManagerCard(article: items[index]), if (index < items.length - 1) const SizedBox(height: AppSpacing.sm)]]),
      ),
    ]);
  }
}

class ArticleManagerCard extends StatelessWidget {
  final PageArticle article;
  const ArticleManagerCard({super.key, required this.article});
  @override Widget build(BuildContext context) => HBCard(padding: const EdgeInsets.all(AppSpacing.sm), child: InkWell(onTap: () => context.push(AppRoutes.articleEditPath(article.page.slug, article.id)), child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(width: 120, height: 76, child: article.coverUrl == null ? const ColoredBox(color: LightModeColors.boscoTint, child: Icon(Icons.article_outlined, color: LightModeColors.bosco)) : Image.network(article.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.broken_image_outlined))))),
    const SizedBox(width: AppSpacing.md),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [ArticleStatus(status: article.status), Text('articles.manager.meta'.tr(namedArgs: {'minutes': '${article.readingTimeMin}', 'views': '${article.viewCount}', 'comments': '${article.commentCount}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)), Text(relativeTime(context, article.updatedAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary))])])),
    const Icon(Icons.chevron_right_rounded),
  ])));
}

class ArticleStatus extends StatelessWidget {
  final String status;
  const ArticleStatus({super.key, required this.status});
  @override Widget build(BuildContext context) => HBStatusChip(kind: switch (status) {'published' => HBStatusKind.approved, 'scheduled' => HBStatusKind.pending, 'archived' => HBStatusKind.neutral, _ => HBStatusKind.info}, label: 'articles.status.$status'.tr());
}

class PagePublishedArticles extends ConsumerWidget {
  final String pageId;
  const PagePublishedArticles({super.key, required this.pageId});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(articlesByPageProvider((pageId: pageId, status: 'published'))).when(
    loading: () => const HBListSkeleton(count: 3),
    error: (_, __) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'articles.errors.load_title'.tr(), message: 'articles.errors.load_message'.tr()),
    data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'articles.public.empty_title'.tr(), message: 'articles.public.empty_message'.tr())) : LayoutBuilder(builder: (context, constraints) { final columns = constraints.maxWidth > 700 ? 3 : constraints.maxWidth > 440 ? 2 : 1; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: .82), itemBuilder: (_, index) => PublicArticleCard(article: items[index])); }),
  );
}

class PublicArticleCard extends StatelessWidget {
  final PageArticle article;
  const PublicArticleCard({super.key, required this.article});
  @override Widget build(BuildContext context) => HBCard(padding: EdgeInsets.zero, child: InkWell(onTap: () => context.push(AppRoutes.articlePath(article.page.slug, article.slug)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(aspectRatio: 16 / 9, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.cardWeb)), child: article.coverUrl == null ? ColoredBox(color: LightModeColors.boscoTint, child: Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text(article.title, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.withColor(LightModeColors.bosco))))) : Image.network(article.coverUrl!, fit: BoxFit.cover))),
    Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('articles.public.label'.tr(namedArgs: {'minutes': '${article.readingTimeMin}'}), style: context.textStyles.labelSmall?.withColor(LightModeColors.bosco)), const SizedBox(height: AppSpacing.xs), Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium), if (article.subtitle?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.xs), Text(article.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary))]])),
  ])));
}

class ArticleFeedCard extends StatelessWidget {
  final PageArticle article;
  const ArticleFeedCard({super.key, required this.article});
  @override Widget build(BuildContext context) => InkWell(onTap: () => context.push(AppRoutes.articlePath(article.page.slug, article.slug)), borderRadius: BorderRadius.circular(AppRadius.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(aspectRatio: 16 / 9, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.media), child: article.coverUrl == null ? ColoredBox(color: LightModeColors.boscoTint, child: Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(article.title, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.titleLarge?.withColor(LightModeColors.bosco))))) : Image.network(article.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.article_outlined))))),
    const SizedBox(height: AppSpacing.sm),
    Text('articles.public.label'.tr(namedArgs: {'minutes': '${article.readingTimeMin}'}), style: context.textStyles.labelSmall?.withColor(LightModeColors.bosco)),
    const SizedBox(height: AppSpacing.xs), Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium),
    if (article.subtitle?.isNotEmpty == true) ...[const SizedBox(height: 2), Text(article.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary))],
    const SizedBox(height: AppSpacing.sm), Row(children: [HBAvatar(name: article.page.name, imageUrl: article.page.avatarUrl, size: 24), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(article.page.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium))]),
  ]));
}