import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_rich_text.dart';
import 'package:hb_social/features/comments/presentation/comment_thread.dart';
import 'package:hb_social/features/composer/providers/composer_providers.dart';
import 'package:hb_social/features/feed/data/reaction_repository.dart';
import 'package:hb_social/features/feed/domain/reaction.dart';
import 'package:hb_social/features/feed/presentation/widgets/share_sheet.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/reels/domain/reel.dart';
import 'package:hb_social/features/reels/presentation/reel_player.dart';
import 'package:hb_social/features/reels/presentation/reel_insights_sheet.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';
import 'package:hb_social/features/platform/presentation/rollout_placeholder_page.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ReelsGate extends ConsumerWidget {
  final Widget child;
  const ReelsGate({super.key, required this.child});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(featureFlagsProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const RolloutPlaceholderPage(module: 'reels'), data: (flags) => flags['reels'] == true ? child : const RolloutPlaceholderPage(module: 'reels'));
}

class ReelsPage extends ConsumerStatefulWidget {
  final String? initialPostId;
  const ReelsPage({super.key, this.initialPostId});
  @override ConsumerState<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends ConsumerState<ReelsPage> {
  final _controller = PageController();
  final _focus = FocusNode();
  int _index = 0;
  Reel? _detail;

  @override void initState() { super.initState(); if (widget.initialPostId != null) _loadDetail(); }
  Future<void> _loadDetail() async { try { final item = await ref.read(reelsRepositoryProvider).detail(widget.initialPostId!); if (mounted) setState(() => _detail = item); } catch (_) {} }
  @override void dispose() { _controller.dispose(); _focus.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final feed = ref.watch(reelsFeedProvider);
    return Focus(autofocus: kIsWeb, focusNode: _focus, onKeyEvent: _key, child: ColoredBox(color: kIsWeb ? LightModeColors.pageWeb : Colors.black, child: SafeArea(child: feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: HBEmptyState(icon: Icons.error_outline, title: 'reels.errors.title'.tr(), message: 'reels.errors.generic'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(reelsFeedProvider)))),
      data: (state) {
        final reels = [if (_detail != null) _detail!, ...state.items.where((item) => item.postId != _detail?.postId)];
        final ads = ref.watch(deliveredAdsProvider(AdPlacementRequest(AdPlacement.reels, count: (reels.length ~/ 6).clamp(1, 10), context: const {'surface': 'reels'}))).value ?? const <DeliveredAd>[];
        final entries = <Object>[];
        for (var index = 0; index < reels.length; index++) { entries.add(reels[index]); if ((index + 1) % 6 == 0 && index ~/ 6 < ads.length) entries.add(ads[index ~/ 6]); }
        if (reels.isEmpty) return Center(child: HBEmptyState(icon: Icons.video_collection_outlined, title: 'reels.empty.title'.tr(), message: 'reels.empty.message'.tr(), action: HBButton.primary(label: 'reels.create'.tr(), icon: Icons.add, onPressed: () => context.push(AppRoutes.reelsNew))));
        return Stack(children: [
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: PageView.builder(controller: _controller, scrollDirection: Axis.vertical, itemCount: entries.length + 1, onPageChanged: (value) { setState(() => _index = value); if (value >= entries.length - 3) ref.read(reelsFeedProvider.notifier).loadMore(); }, itemBuilder: (context, index) { if (index == entries.length) return ReelsEndCard(onReview: () { ref.read(reelsFeedProvider.notifier).review(); _controller.jumpToPage(0); }); final item = entries[index]; return item is Reel ? ReelPageItem(reel: item, active: index == _index) : ReelAdPage(ad: item as DeliveredAd, active: index == _index); }))),
          Positioned(top: 8, left: 8, child: IconButton(onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
          Positioned(top: 8, right: 8, child: Consumer(builder: (context, ref, _) { final allowed = ref.watch(reelUploadAllowanceProvider).value; return Tooltip(message: allowed?.ok == false ? 'reels.errors.${allowed?.reason}'.tr() : 'reels.create'.tr(), child: IconButton(onPressed: allowed?.ok == true ? () => context.push(AppRoutes.reelsNew) : null, icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white))); })),
          if (kIsWeb) Positioned(right: 24, top: MediaQuery.sizeOf(context).height / 2 - 52, child: Column(children: [IconButton(onPressed: _index > 0 ? () => _controller.previousPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut) : null, icon: const Icon(Icons.keyboard_arrow_up_rounded)), IconButton(onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut), icon: const Icon(Icons.keyboard_arrow_down_rounded))])),
        ]);
      },
    ))));
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) { _controller.nextPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut); return KeyEventResult.handled; }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && _index > 0) { _controller.previousPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut); return KeyEventResult.handled; }
    return KeyEventResult.ignored;
  }
}

class ReelAdPage extends ConsumerStatefulWidget {
  final DeliveredAd ad;
  final bool active;
  const ReelAdPage({super.key, required this.ad, required this.active});
  @override ConsumerState<ReelAdPage> createState() => _ReelAdPageState();
}

class _ReelAdPageState extends ConsumerState<ReelAdPage> {
  bool recorded = false;
  @override void didChangeDependencies() { super.didChangeDependencies(); _record(); }
  @override void didUpdateWidget(covariant ReelAdPage oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.active != widget.active) _record(); }
  void _record() { if (!widget.active || recorded) return; recorded = true; unawaited(ref.read(adsDeliveryRepositoryProvider.future).then((repo) => repo.recordImpression(widget.ad.adId, AdPlacement.reels)).catchError((_) {})); }
  Future<void> _open() async { unawaited(ref.read(adsDeliveryRepositoryProvider.future).then((repo) => repo.recordClick(widget.ad.adId, AdPlacement.reels)).catchError((_) {})); final url = widget.ad.creative.destinationUrl; if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
  @override Widget build(BuildContext context) { final media = widget.ad.creative.media.firstOrNull; return ColoredBox(color: Colors.black, child: InkWell(onTap: _open, child: Stack(fit: StackFit.expand, children: [if (media != null && media.path.isNotEmpty) Image.network(media.path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()), Positioned(left: 16, right: 16, bottom: 28, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('reels.sponsored'.tr(), style: AppText.caption.copyWith(color: Colors.white70)), const SizedBox(height: 6), Text(widget.ad.creative.headline, style: AppText.title.copyWith(color: Colors.white)), const SizedBox(height: 6), Text(widget.ad.creative.body, style: AppText.body.copyWith(color: Colors.white)), const SizedBox(height: 12), HBButton.primary(label: 'ads.cta.${widget.ad.creative.callToAction}'.tr(), onPressed: _open)]))]))); }
}

class ReelPageItem extends ConsumerStatefulWidget {
  final Reel reel;
  final bool active;
  const ReelPageItem({super.key, required this.reel, required this.active});
  @override ConsumerState<ReelPageItem> createState() => _ReelPageItemState();
}

class _ReelPageItemState extends ConsumerState<ReelPageItem> {
  late bool liked = widget.reel.myReaction == 'like';
  late int likes = widget.reel.reactionCount;
  bool revealed = false;
  FeedPost get post => FeedPost(id: widget.reel.postId, author: widget.reel.author, content: widget.reel.caption, kind: 'reel', locationName: widget.reel.locationName, reactionCount: likes, commentCount: widget.reel.commentCount, shareCount: widget.reel.shareCount, createdAt: widget.reel.createdAt, media: const [], myReaction: liked ? 'like' : null, countryCode: widget.reel.countryCode, isSensitive: widget.reel.isSensitive);

  Future<void> _like() async { try { final result = await ReactionRepository(ref.read(reelsRepositoryProvider).client).toggle(widget.reel.postId, ReactionType.like); setState(() { liked = result.myReaction != null; likes = result.reactionCount; }); } catch (_) {} }

  @override Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    ReelPlayer(hls: widget.reel.hls, thumbnail: widget.reel.thumbnailUrl, aspectRatio: widget.reel.aspectRatio, active: widget.active && (!widget.reel.isSensitive || revealed), onThreeSeconds: () => ref.read(reelsRepositoryProvider).recordView(widget.reel.postId, 3000, false), onCompleted: () => ref.read(reelsRepositoryProvider).recordView(widget.reel.postId, widget.reel.durationSeconds * 1000, true), onDoubleTap: _like),
    if (widget.reel.isSensitive && !revealed) ColoredBox(color: Colors.black87, child: Center(child: HBButton.secondary(label: 'reels.sensitive.show'.tr(), icon: Icons.visibility_outlined, onPressed: () => setState(() => revealed = true)))),
    Positioned(left: 16, right: 88, bottom: 28, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [HBAvatar(name: widget.reel.author.displayName, imageUrl: widget.reel.author.avatarUrl, size: 38), const SizedBox(width: 8), Flexible(child: Text(widget.reel.author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.copyWith(color: Colors.white, fontWeight: FontWeight.w700))), if (widget.reel.author.isVerified) ...[const SizedBox(width: 4), HBBadge.verification(level: widget.reel.author.verificationLevel, verifiedAt: widget.reel.author.verifiedAt)], if (!widget.reel.isFollowing) ...[const SizedBox(width: 8), FollowButton(userId: widget.reel.author.id, size: HBButtonSize.sm)]]),
      if (widget.reel.caption?.isNotEmpty == true) ...[const SizedBox(height: 10), HBRichText(text: widget.reel.caption!, style: AppText.body.copyWith(color: Colors.white), maxLines: 4, overflow: TextOverflow.ellipsis)],
      if (widget.reel.locationName != null) ...[const SizedBox(height: 6), Text(widget.reel.locationName!, style: AppText.caption.copyWith(color: Colors.white70))],
    ])),
    Positioned(right: 12, bottom: 34, child: ReelActions(reel: widget.reel, post: post, liked: liked, likes: likes, onLike: _like)),
  ]);
}

class ReelActions extends ConsumerWidget {
  final Reel reel;
  final FeedPost post;
  final bool liked;
  final int likes;
  final VoidCallback onLike;
  const ReelActions({super.key, required this.reel, required this.post, required this.liked, required this.likes, required this.onLike});
  @override Widget build(BuildContext context, WidgetRef ref) => Column(mainAxisSize: MainAxisSize.min, children: [
    ReelAction(icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, count: likes, color: liked ? LightModeColors.danger : Colors.white, onTap: onLike),
    ReelAction(icon: Icons.chat_bubble_outline_rounded, count: reel.commentCount, onTap: () => _comments(context)),
    ReelAction(icon: Icons.send_outlined, count: reel.shareCount, onTap: () => showShareSheet(context, post)),
    ReelAction(icon: Icons.more_horiz_rounded, onTap: () => _menu(context, ref)),
  ]);
  void _comments(BuildContext context) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => DraggableScrollableSheet(expand: false, initialChildSize: .9, builder: (_, controller) => CommentPanel(postId: reel.postId, postAuthorId: reel.author.id, fixedComposer: true)));
  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final own = ref.read(reelsRepositoryProvider).currentUserId == reel.author.id;
    final action = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [if (own) ListTile(leading: const Icon(Icons.insights_outlined), title: Text('reels.insights.title'.tr()), onTap: () => context.pop('insights')), if (own) ListTile(leading: const Icon(Icons.delete_outline), title: Text('reels.delete'.tr()), onTap: () => context.pop('delete')), if (!own) ListTile(leading: const Icon(Icons.visibility_off_outlined), title: Text('safety.hide_post'.tr()), onTap: () => context.pop('hide')), if (!own) ListTile(leading: const Icon(Icons.flag_outlined), title: Text('safety.report_post'.tr()), onTap: () => context.pop('report'))])));
    if (!context.mounted || action == null) return;
    if (action == 'insights') showReelInsights(context, reel.postId);
    if (action == 'report') showReportSheet(context, targetType: 'post', targetId: reel.postId);
    if (action == 'hide') { await ref.read(safetyRepositoryProvider).hidePost(reel.postId); ref.invalidate(reelsFeedProvider); }
    if (action == 'delete') { await ref.read(composerRepositoryProvider).deletePost(reel.postId); ref.invalidate(reelsFeedProvider); ref.invalidate(reelsByUserProvider(reel.author.id)); }
  }
}

class ReelAction extends StatelessWidget {
  final IconData icon; final int? count; final Color color; final VoidCallback onTap;
  const ReelAction({super.key, required this.icon, this.count, this.color = Colors.white, required this.onTap});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 14), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Column(children: [Icon(icon, color: color, size: 30), if (count != null) Text('$count', style: AppText.small.copyWith(color: Colors.white))])));
}

class ReelsEndCard extends StatelessWidget {
  final VoidCallback onReview;
  const ReelsEndCard({super.key, required this.onReview});
  @override Widget build(BuildContext context) => ColoredBox(color: Colors.black, child: Center(child: HBEmptyState(icon: Icons.check_circle_outline_rounded, title: 'reels.end.title'.tr(), message: 'reels.end.message'.tr(), action: HBButton.secondary(label: 'reels.end.review'.tr(), onPressed: onReview))));
}