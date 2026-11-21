import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';
import 'package:hb_social/features/notifications/domain/app_notification.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/features/notifications/presentation/notification_text.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart' as social_graph;
import 'package:hb_social/features/chat/providers/chat_providers.dart';

/// Notifiche screen: all notifications, mentions or requests. Refreshes on open,
/// has pull-to-refresh on mobile and refresh button on web.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _invalidateOnOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _invalidateOnOpen();
    }
  }

  void _invalidateOnOpen() {
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(social_graph.pendingFriendRequestCountProvider);
  }

  Future<void> _refresh() async {
    _invalidateOnOpen();
    await ref.refresh(notificationsListProvider.future);
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationsListProvider.notifier).markAllRead();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('notifications.action_error'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(notificationsTabProvider);
    final notifications = ref.watch(notificationsListProvider);

    final body = notifications.when(
      loading: () => const HBListSkeleton(showTrailing: false),
      error: (error, stackTrace) => HBCard(
        child: HBEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'notifications.error_title'.tr(),
          message: 'notifications.error_message'.tr(),
          action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => _refresh()),
        ),
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return HBCard(child: HBEmptyState(icon: Icons.notifications_none_rounded, title: 'notifications.empty_title'.tr(), message: 'notifications.empty_message'.tr()));
        }
        return Column(
          children: [
            for (var index = 0; index < page.items.length; index++) ...[
              NotificationCard(notification: page.items[index]),
              if (index < page.items.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
            if (page.hasMore) ...[
              const SizedBox(height: AppSpacing.md),
              page.isLoadingMore
                  ? const HBListSkeleton(count: 1, showTrailing: false)
                  : HBButton.secondary(label: 'notifications.load_more'.tr(), onPressed: () => ref.read(notificationsListProvider.notifier).loadMore()),
            ],
          ],
        );
      },
    );

    final isMobile = MediaQuery.of(context).size.width < 600;
    final content = isMobile
        ? RefreshIndicator(onRefresh: _refresh, child: SingleChildScrollView(child: body))
        : body;

    return ListPageScaffold(
      title: 'nav.notifications'.tr(),
      action: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!isMobile) HBButton.ghost(label: 'common.refresh'.tr(), size: HBButtonSize.sm, onPressed: _refresh),
        if (!isMobile) const SizedBox(width: AppSpacing.sm),
        HBButton.ghost(
          label: 'notifications.mark_all_read'.tr(),
          size: HBButtonSize.sm,
          onPressed: _markAllRead,
        ),
      ]),
      filters: HBSegmentedTabs(
        labels: ['notifications.tab_all'.tr(), 'notifications.tab_mentions'.tr(), 'notifications.tab_requests'.tr()],
        selectedIndex: NotificationsTab.values.indexOf(tab),
        onChanged: (index) { ref.read(notificationsTabProvider.notifier).state = NotificationsTab.values[index]; _invalidateOnOpen(); },
      ),
      body: content,
    );
  }
}

class NotificationCard extends ConsumerStatefulWidget {
  final AppNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  ConsumerState<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<NotificationCard> {
  late String? _optimisticStatus;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _optimisticStatus = widget.notification.status;
  }

  Future<void> _respond(bool accept) async {
    final requestId = widget.notification.requestId;
    if (requestId == null) return;
    setState(() { _working = true; _optimisticStatus = accept ? 'accepted' : 'declined'; });
    try {
      await ref.read(social_graph.socialGraphRepositoryProvider).respond(requestId, accept);
      ref.invalidate(social_graph.pendingFriendRequestCountProvider); ref.invalidate(social_graph.receivedRequestsProvider); ref.invalidate(social_graph.peopleSuggestionsProvider);
    } catch (e) {
      final errorMsg = e.toString();
      if ((errorMsg.contains('friend_request_not_pending') || errorMsg.contains('friend_request_not_found')) && mounted) {
        ref.invalidate(notificationsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('friendship.already_handled'.tr())));
      } else if (mounted) {
        setState(() => _optimisticStatus = widget.notification.status);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final actor = notification.actorName ?? 'notifications.system_actor'.tr();
    final systemSafety = const {'strike','account_suspended','account_reactivated','account_banned','content_hidden','content_removed','report_resolved','data_export_ready','data_export_failed','account_deletion_scheduled','account_deletion_cancelled'}.contains(notification.kind);
    final systemEvent = const {'event_waitlist_promoted', 'event_paid', 'event_checkin', 'event_cancelled'}.contains(notification.kind);
    final systemSighting = notification.kind == 'sighting_alert';
    final systemVerification = const {'verification_approved', 'verification_rejected', 'verification_expiring', 'verification_expired'}.contains(notification.kind);
    final systemOrder = const {'order_paid', 'order_shipped', 'order_completed', 'order_expired', 'order_cancelled', 'order_refunded', 'order_disputed', 'order_refund_requested', 'order_refund_declined'}.contains(notification.kind);
    final systemAds = NotificationAdsKinds.all.contains(notification.kind);
    final systemListing = const {'listing_in_review','listing_approved','listing_rejected'}.contains(notification.kind);
    final systemReel = const {'reel_ready','reel_failed'}.contains(notification.kind);
    final systemScheduledPost = notification.kind == 'post_published';
    final path = const {'data_export_ready','data_export_failed','account_deletion_scheduled','account_deletion_cancelled','account_reactivated','account_banned'}.contains(notification.kind) ? AppRoutes.privacySecurity : notification.kind == 'report_resolved' ? null : systemOrder && notification.targetId != null ? AppRoutes.orderPath(notification.targetId!) : systemVerification && notification.pageSlug != null ? AppRoutes.pageStudioPath(notification.pageSlug!) : systemVerification ? AppRoutes.verification : systemSighting && notification.targetId != null ? AppRoutes.sightingDetailPath(notification.targetId!) : notification.kind == 'message' && notification.conversationId != null ? AppRoutes.conversationDetailPath(notification.conversationId!) : notification.kind == 'event_rsvp' && notification.targetId != null ? AppRoutes.eventManagePath(notification.targetId!) : systemEvent && notification.targetId != null ? AppRoutes.eventDetailPath(notification.targetId!) : const {'page_role', 'page_follower_new'}.contains(notification.kind) && notification.pageSlug != null ? (notification.kind == 'page_follower_new' ? AppRoutes.pageStudioPath(notification.pageSlug!) : AppRoutes.pageDetailPath(notification.pageSlug!)) : const {'forum_request', 'forum_member_joined'}.contains(notification.kind) && notification.forumSlug != null ? AppRoutes.forumStudioPath(notification.forumSlug!) : notification.kind == 'forum_accepted' && notification.forumSlug != null ? AppRoutes.forumDetailPath(notification.forumSlug!) : const {'forum_reply', 'forum_solution', 'forum_mention', 'forum_reply_like', 'forum_thread_new'}.contains(notification.kind) && notification.forumSlug != null && notification.threadId != null ? '${AppRoutes.threadPath(notification.forumSlug!, notification.threadId!)}${notification.targetId == null ? '' : '?reply=${notification.targetId}'}' : const {'group_request', 'group_member_joined'}.contains(notification.kind) && notification.groupSlug != null ? AppRoutes.groupStudioPath(notification.groupSlug!) : notification.kind == 'group_accepted' && notification.groupSlug != null ? AppRoutes.groupDetailPath(notification.groupSlug!) : notification.kind == 'group_post_new' && notification.postId != null ? AppRoutes.postPath(notification.postId!) : notification.kind == 'strike' ? AppRoutes.privacySecurity : notification.kind == 'account_suspended' ? AppRoutes.suspended : notification.targetType == 'comment'
        ? (notification.postId == null ? null : '${AppRoutes.postPath(notification.postId!)}?comment=${notification.targetId}')
        : notification.targetType == 'post'
            ? (notification.targetId == null ? null : AppRoutes.postPath(notification.targetId!))
            : const {'follow', 'friend_request', 'friend_accepted'}.contains(notification.kind) && notification.actorUsername != null
                ? AppRoutes.publicProfilePath(notification.actorUsername!)
                : null;
    final effectivePath = systemScheduledPost && notification.postId != null ? AppRoutes.postPath(notification.postId!) : notification.kind == 'live_started' && notification.streamId != null ? AppRoutes.livePath(notification.streamId!) : notification.kind == 'call_incoming' && notification.callId != null ? AppRoutes.callPath(notification.callId!, incoming: true) : notification.kind == 'call_missed' ? AppRoutes.calls : notification.kind == 'reel_ready' && notification.postId != null ? AppRoutes.reelPath(notification.postId!) : notification.kind == 'reel_failed' ? AppRoutes.reelsMine : notification.kind == 'broadcast' ? notification.route : const {'support_reply','support_status'}.contains(notification.kind) && notification.ticketId != null ? AppRoutes.supportTicketPath(notification.ticketId!) : systemListing && notification.targetId != null ? AppRoutes.marketplaceDetailPath(notification.targetId!) : const {'ads_boost_started', 'ads_boost_completed'}.contains(notification.kind) ? AppRoutes.boosts : systemAds && notification.targetId != null ? (notification.kind == 'ads_paused_funds' || notification.targetType == 'ad_account' ? '${AppRoutes.adAccountPath(notification.targetId!)}?tab=billing' : AppRoutes.adCampaignPath(notification.targetId!)) : path;
    final isPending = _optimisticStatus == null || _optimisticStatus!.isEmpty || _optimisticStatus == 'pending';
    return HBCard(
      radius: AppRadius.md,
      child: InkWell(onTap: () async {
        try {
          await ref.read(notificationsListProvider.notifier).markRead(notification.id);
          if (notification.kind == 'message' && notification.conversationId != null) {
            await ref.read(chatRepositoryProvider).markRead(notification.conversationId!);
            ref.invalidate(unreadConversationsCountProvider);
            ref.invalidate(conversationsProvider);
          }
        } catch (_) {}
        if (effectivePath != null && context.mounted) {
          final listingId = systemListing ? notification.targetId : notification.targetType == 'listing' ? notification.targetId : null;
          if (listingId != null) {
            try { await ref.read(listingDetailResponseProvider(listingId).future); }
            on AppException catch (error) { if (context.mounted && error.messageKey == 'marketplace.firearms.notice.platform') ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); return; }
          }
          if (context.mounted) context.push(effectivePath);
        }
      }, child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (systemSafety || systemEvent || systemSighting || systemVerification || systemOrder || systemAds || systemListing || systemReel || systemScheduledPost) Container(width: 44, height: 44, decoration: const BoxDecoration(color: LightModeColors.lightPrimarySoft, shape: BoxShape.circle), child: Icon(systemScheduledPost ? Icons.schedule_outlined : systemSafety || systemVerification ? Icons.shield_rounded : systemSighting ? Icons.visibility_outlined : systemOrder ? Icons.receipt_long_outlined : systemListing ? Icons.storefront_outlined : systemAds ? Icons.campaign_outlined : systemReel ? Icons.video_collection_outlined : Icons.event_outlined, color: LightModeColors.lightPrimary)) else HBAvatar(name: actor, imageUrl: notification.actorAvatarUrl, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizedNotificationTitle(notification), style: context.textStyles.bodyMedium?.copyWith(fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700)),
                if (notification.kind == 'friend_request') ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (isPending) Wrap(spacing: AppSpacing.sm, children: [HBButton.primary(label: 'friendship.accept'.tr(), size: HBButtonSize.sm, isLoading: _working, onPressed: _working ? null : () => _respond(true)), HBButton.soft(label: 'friendship.decline'.tr(), size: HBButtonSize.sm, onPressed: _working ? null : () => _respond(false))]) else Text(_optimisticStatus == 'accepted' ? 'friendship.status_accepted'.tr() : _optimisticStatus == 'declined' ? 'friendship.status_declined'.tr() : 'friendship.status_cancelled'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary)),
                ],
                if (notification.body != null && notification.body!.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), Text(notification.body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))],
                const SizedBox(height: AppSpacing.xs),
                Text(relativeTime(context, notification.createdAt), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
              ],
            ),
          ),
          if (!notification.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: LightModeColors.lightPrimary, shape: BoxShape.circle)),
        ],
      )),
    );
  }
}
