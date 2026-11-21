import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/comments/presentation/comment_thread.dart';
import 'package:hb_social/features/feed/presentation/widgets/reaction_button.dart';
import 'package:hb_social/features/feed/providers/reaction_providers.dart';
import 'package:hb_social/features/pages/articles/domain/article.dart';
import 'package:hb_social/features/pages/articles/presentation/article_editor_page.dart';
import 'package:hb_social/features/pages/articles/presentation/page_articles.dart';
import 'package:hb_social/features/pages/articles/providers/articles_providers.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/core/widgets/translatable_text.dart';
import 'package:hb_social/core/services/seo_service.dart';

final Set<String> _viewedArticleIds = {};

class ArticleDetailPage extends ConsumerWidget {
  final String pageSlug;
  final String slug;
  const ArticleDetailPage({super.key, required this.pageSlug, required this.slug});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(articleByPathProvider((pageSlug: pageSlug, slug: slug))).when(
    loading: () => const PageColumns(center: HBListSkeleton(count: 6)),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'articles.errors.load_title'.tr(), message: 'articles.errors.load_message'.tr()))),
    data: (article) => article == null || article.status != 'published' && !article.canEdit ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'articles.public.unavailable_title'.tr(), message: 'articles.public.unavailable_message'.tr()))) : ArticleReader(article: article),
  );
}

class ArticleReader extends ConsumerStatefulWidget {
  final PageArticle article;
  const ArticleReader({super.key, required this.article});
  @override ConsumerState<ArticleReader> createState() => _ArticleReaderState();
}

class _ArticleReaderState extends ConsumerState<ArticleReader> {
  bool comments = false;
  @override void initState() { super.initState(); if (widget.article.status == 'published' && _viewedArticleIds.add(widget.article.id)) ref.read(articlesRepositoryProvider).recordView(widget.article.id).catchError((_) {}); }
  @override Widget build(BuildContext context) {
    final article = widget.article;
    SeoService.update(title: '${article.title} - HB Social', description: article.subtitle ?? 'seo.article_description'.tr(), path: AppRoutes.articlePath(article.page.slug, article.slug), imageUrl: article.coverUrl);
    return PageColumns(centerMaxWidth: 720, center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      if (article.coverUrl != null) ClipRRect(borderRadius: BorderRadius.circular(AppRadius.cardWeb), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(article.coverUrl!, fit: BoxFit.cover))),
      Padding(padding: EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width < 700 ? AppSpacing.md : 0, AppSpacing.xl, MediaQuery.sizeOf(context).width < 700 ? AppSpacing.md : 0, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TranslatableText(type: 'article', id: article.id, field: 'title', text: article.title, style: context.textStyles.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
        if (article.subtitle?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.sm), TranslatableText(type: 'article', id: article.id, field: 'subtitle', text: article.subtitle!, style: context.textStyles.titleMedium?.withColor(LightModeColors.textSecondary))],
        const SizedBox(height: AppSpacing.lg),
        Row(children: [InkWell(onTap: () => context.push(AppRoutes.pageDetailPath(article.page.slug)), child: HBAvatar(name: article.page.name, imageUrl: article.page.avatarUrl, size: 42)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(article.page.name, style: context.textStyles.titleSmall)), if (article.page.verificationStatus == 'verified') ...[const SizedBox(width: 4), const HBBadge(kind: HBBadgeKind.verified)]]), Text('articles.public.byline'.tr(namedArgs: {'author': article.author.displayName, 'date': article.publishedAt == null ? '' : relativeTime(context, article.publishedAt!), 'minutes': '${article.readingTimeMin}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary))]))]),
        const SizedBox(height: AppSpacing.xl), TranslatableText(type: 'article', id: article.id, field: 'body', text: article.body ?? '', builder: (text) => ArticleMarkdownBody(data: text)), const SizedBox(height: AppSpacing.xl),
        if (article.postId != null) ArticleSocialBar(article: article, commentsOpen: comments, onComments: () => setState(() => comments = !comments)),
        if (comments && article.postId != null) ...[const Divider(), CommentPanel(postId: article.postId!, postAuthorId: article.author.id)],
        const SizedBox(height: AppSpacing.xl), Text('articles.public.more'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), ArticleMoreGrid(article: article),
      ])),
    ]))]));
  }
}

class ArticleSocialBar extends ConsumerWidget {
  final PageArticle article;
  final bool commentsOpen;
  final VoidCallback onComments;
  const ArticleSocialBar({super.key, required this.article, required this.commentsOpen, required this.onComments});
  @override Widget build(BuildContext context, WidgetRef ref) => Row(children: [
    ReactionButton(postId: article.postId!, compact: true, initialReaction: article.myReaction, initialCount: article.reactionCount, onToggle: (type) => ref.read(reactionRepositoryProvider).toggle(article.postId!, type)),
    HBButton.ghost(label: '${article.commentCount}', icon: Icons.chat_bubble_outline_rounded, onPressed: onComments),
    HBButton.ghost(label: 'articles.public.share'.tr(), icon: Icons.ios_share_outlined, onPressed: () async { await Clipboard.setData(ClipboardData(text: Uri.base.toString())); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('share.link_copied'.tr()))); }),
    const Spacer(), HBButton.icon(icon: Icons.flag_outlined, tooltip: 'safety.report_post'.tr(), onPressed: () => showReportSheet(context, targetType: 'post', targetId: article.postId!)),
  ]);
}

class ArticleMoreGrid extends ConsumerWidget {
  final PageArticle article;
  const ArticleMoreGrid({super.key, required this.article});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(articlesByPageProvider((pageId: article.pageId, status: 'published'))).when(loading: () => const HBListSkeleton(count: 2), error: (_, __) => const SizedBox.shrink(), data: (items) { final other = items.where((item) => item.id != article.id).take(3).toList(); if (other.isEmpty) return const SizedBox.shrink(); return LayoutBuilder(builder: (_, constraints) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: other.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth > 560 ? 3 : 1, childAspectRatio: .85, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm), itemBuilder: (_, index) => PublicArticleCard(article: other[index]))); });
}