import 'package:easy_localization/easy_localization.dart';
import 'package:hb_social/features/notifications/domain/app_notification.dart';
import 'package:intl/intl.dart';

String localizedNotificationTitle(AppNotification notification) {
  if (notification.kind == 'post_published') return 'posts.scheduled.notification'.tr(namedArgs: {'preview': notification.preview ?? ''});
  if (notification.kind == 'live_started') return 'live.notification_started'.tr(namedArgs: {'host': notification.actorName ?? '', 'title': notification.conversationTitle ?? ''});
  if (notification.kind == 'call_incoming') return 'calls.notification_incoming'.tr(namedArgs: {'caller': notification.actorName ?? ''});
  if (notification.kind == 'call_missed') return 'calls.notification_missed'.tr(namedArgs: {'caller': notification.actorName ?? ''});
  if (notification.kind == 'reel_ready') return 'reels.notifications.ready'.tr();
  if (notification.kind == 'reel_failed') return 'reels.notifications.failed'.tr(namedArgs: {'reason': 'reels.failure.${notification.reason ?? 'processing'}'.tr()});
  if (notification.kind == 'broadcast') return notification.conversationTitle ?? notification.body ?? '';
  if (notification.kind == 'support_reply') return 'support.notification.reply'.tr(namedArgs: {'subject': notification.threadTitle ?? '', 'preview': notification.preview ?? ''});
  if (notification.kind == 'support_status') return 'support.notification.status'.tr(namedArgs: {'subject': notification.threadTitle ?? '', 'status': 'support.status.${notification.status ?? 'open'}'.tr()});
  if (const {'listing_in_review','listing_approved','listing_rejected'}.contains(notification.kind)) return 'p42.marketplace_review.notifications.${notification.kind}'.tr(namedArgs: {'note': notification.reason ?? ''});
  if (const {'account_reactivated','account_banned','content_hidden','content_removed','report_resolved','data_export_ready','data_export_failed','account_deletion_scheduled','account_deletion_cancelled'}.contains(notification.kind)) return 'p41.notifications.${notification.kind}'.tr(namedArgs: {'date': notification.expiresAt == null ? '' : DateFormat.yMd().format(notification.expiresAt!.toLocal()), 'outcome': notification.status ?? ''});
  if (notification.kind == 'ads_boost_started') return 'boost.confirm_active'.tr(namedArgs: {'type': 'boost.type.${notification.targetType ?? 'post'}'.tr()});
  if (notification.kind == 'ads_boost_completed') return 'boost.finished'.tr();
  if (NotificationAdsKinds.all.contains(notification.kind)) return 'ads_schema.notification.${notification.kind}'.tr(namedArgs: {'reason': notification.reason ?? ''});
  if (const {'order_cancelled', 'order_refunded', 'order_disputed', 'order_refund_requested', 'order_refund_declined'}.contains(notification.kind)) return 'p34b.notification.${notification.kind}'.tr(namedArgs: {'note': notification.reason ?? ''});
  if (const {'order_paid', 'order_shipped', 'order_completed', 'order_expired'}.contains(notification.kind)) return 'orders.notification.${notification.kind}'.tr(namedArgs: {'carrier': notification.orderCarrier ?? '', 'tracking': notification.orderTracking ?? ''});
  if (const {'verification_approved', 'verification_rejected', 'verification_expiring', 'verification_expired'}.contains(notification.kind)) {
    return 'verification.notifications.${notification.kind}'.tr(namedArgs: {'badge': 'verification.badge.${notification.verificationBadgeType ?? 'hunter'}'.tr(), 'reason': notification.reason ?? '', 'days': '${notification.verificationDaysLeft ?? 0}', 'page': notification.pageName ?? ''});
  }
  if (notification.kind == 'strike') {
    final reason = 'safety.reasons.${notification.reason ?? 'other'}'.tr();
    return 'notifications.kind_strike'.tr(namedArgs: {'reason': reason});
  }
  if (notification.kind == 'account_suspended') return 'notifications.kind_account_suspended'.tr();
  if (notification.kind == 'sighting_alert') {
    final args = {'alert_name': notification.alertName ?? '', 'n': '${notification.alertAnimalsCount ?? 1}', 'species': notification.alertSpeciesName ?? '', 'municipality': notification.alertMunicipalityName ?? '', 'km': notification.alertDistanceKm?.toStringAsFixed(1) ?? ''};
    if (notification.alertMunicipalityName != null && notification.alertDistanceKm != null) return 'notifications.sighting_alert_place_distance'.tr(namedArgs: args);
    if (notification.alertMunicipalityName != null) return 'notifications.sighting_alert_place'.tr(namedArgs: args);
    if (notification.alertDistanceKm != null) return 'notifications.sighting_alert_distance'.tr(namedArgs: args);
    return 'notifications.sighting_alert'.tr(namedArgs: args);
  }
  final actor = notification.actorName ?? 'notifications.system_actor'.tr();
  if (notification.kind == 'message') {
    final preview = notification.messageKind == 'image' ? 'chat.photo'.tr() : notification.messageKind == 'voice' ? 'chat.voice'.tr() : notification.messageKind == 'gif' ? 'gifs.preview'.tr() : (notification.preview ?? '');
    return notification.conversationKind == 'group'
        ? 'chat_notifications.group'.tr(namedArgs: {'title': notification.conversationTitle ?? '', 'sender': actor, 'preview': preview})
        : 'chat_notifications.direct'.tr(namedArgs: {'sender': actor, 'preview': preview});
  }
  if (notification.kind == 'group_request') {
    final base = 'notifications.kind_group_request'.tr(namedArgs: {'actor': actor, 'group': notification.groupName ?? ''});
    if (notification.status == 'accepted') return '$base · ${'notifications.status_accepted'.tr()}';
    if (notification.status == 'declined') return '$base · ${'notifications.status_declined'.tr()}';
    return base;
  }
  if (notification.kind == 'group_accepted') return 'notifications.kind_group_accepted'.tr(namedArgs: {'group': notification.groupName ?? ''});
  if (notification.kind == 'page_role') return 'notifications.kind_page_role'.tr(namedArgs: {'actor': actor, 'page': notification.pageName ?? '', 'role': 'pages.roles.${notification.role ?? 'editor'}'.tr()});
  if (notification.kind == 'forum_reply') return (notification.toReply ? 'notifications.kind_forum_reply_to_reply' : 'notifications.kind_forum_reply').tr(namedArgs: {'actor': actor, 'thread': notification.threadTitle ?? ''});
  if (notification.kind == 'forum_solution') return 'notifications.kind_forum_solution'.tr(namedArgs: {'actor': actor, 'thread': notification.threadTitle ?? ''});
  if (notification.kind == 'forum_mention') return 'notif_settings.notice_forum_mention'.tr(namedArgs: {'actor': actor, 'thread': notification.threadTitle ?? ''});
  if (notification.kind == 'forum_reply_like') return 'notif_settings.notice_forum_reply_like'.tr(namedArgs: {'actor': actor});
  if (notification.kind == 'forum_member_joined') return 'notif_settings.notice_forum_member_joined'.tr(namedArgs: {'actor': actor, 'forum': notification.forumName ?? ''});
  if (notification.kind == 'forum_thread_new') return 'notif_settings.notice_forum_thread_new'.tr(namedArgs: {'actor': actor, 'thread': notification.threadTitle ?? '', 'forum': notification.forumName ?? ''});
  if (notification.kind == 'group_member_joined') return 'notif_settings.notice_group_member_joined'.tr(namedArgs: {'actor': actor, 'group': notification.groupName ?? ''});
  if (notification.kind == 'group_post_new') return 'notif_settings.notice_group_post_new'.tr(namedArgs: {'actor': actor, 'group': notification.groupName ?? ''});
  if (notification.kind == 'page_follower_new') return 'notif_settings.notice_page_follower_new'.tr(namedArgs: {'actor': actor, 'page': notification.pageName ?? ''});
  if (notification.kind == 'forum_request') {
    final base = 'notifications.kind_forum_request'.tr(namedArgs: {'actor': actor, 'forum': notification.forumName ?? ''});
    if (notification.status == 'accepted') return '$base · ${'notifications.status_accepted'.tr()}';
    if (notification.status == 'declined') return '$base · ${'notifications.status_declined'.tr()}';
    return base;
  }
  if (notification.kind == 'forum_accepted') return 'notifications.kind_forum_accepted'.tr(namedArgs: {'forum': notification.forumName ?? ''});
  if (notification.kind == 'event_rsvp') return 'notifications.kind_event_rsvp'.tr(namedArgs: {'actor': actor, 'event': notification.eventTitle ?? ''});
  if (notification.kind == 'event_waitlist_promoted') return 'notifications.kind_event_waitlist_promoted'.tr(namedArgs: {'event': notification.eventTitle ?? ''});
  if (notification.kind == 'event_paid') return 'notifications.kind_event_paid'.tr(namedArgs: {'event': notification.eventTitle ?? ''});
  if (notification.kind == 'event_checkin') return 'notifications.kind_event_checkin'.tr(namedArgs: {'event': notification.eventTitle ?? ''});
  if (notification.kind == 'event_cancelled') return 'notifications.kind_event_cancelled'.tr(namedArgs: {'event': notification.eventTitle ?? ''});
  const supported = {'follow', 'reaction', 'comment', 'reply', 'comment_like', 'share', 'mention', 'follow_request', 'event_request', 'friend_request', 'friend_accepted'};
  return (supported.contains(notification.kind) ? 'notifications.kind_${notification.kind}' : 'notifications.kind_generic').tr(namedArgs: {'actor': actor});
}

class NotificationAdsKinds {
  static const all = {'ads_billing', 'ad_campaign_approved', 'ad_campaign_rejected', 'ad_charge_succeeded', 'ad_charge_failed', 'ad_account_suspended', 'ads_boost_started', 'ads_boost_completed'};
  const NotificationAdsKinds._();
}