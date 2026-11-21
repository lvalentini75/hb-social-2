import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_marketing_image.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/search/providers/search_providers.dart';
import 'package:hb_social/features/social_graph/domain/online_friend.dart';
import 'package:hb_social/features/social_graph/providers/online_friends_provider.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_placement.dart';

/// PD4 right rail (368 px): zone card, Messaggi, Online, Eventi vicino a te,
/// Di tendenza, invite card and the P38 sponsored slot. Every card hides
/// itself when it has no real data.
class RightRail extends ConsumerWidget {
  final Widget? contextCard;
  const RightRail({super.key, this.contextCard});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: EdgeInsets.zero,
    children: [
      if (contextCard != null) ...[contextCard!, const SizedBox(height: AppSpacing.md)],
      const RailZoneCard(),
      const RailMessagesCard(),
      const RailOnlineCard(),
      const RailEventsCard(),
      const RailTrendingCard(),
      const RailInviteCard(),
      const SponsoredPlacement(placement: AdPlacement.rightRail, variant: AdPreviewVariant.rightRail),
      const SizedBox(height: AppSpacing.lg),
    ],
  );
}

/// Shared white card shell of the rail: radius 20, shadow, padding 20.
class RailCard extends StatelessWidget {
  final String? title;
  final Widget? titleTrailing;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const RailCard({super.key, this.title, this.titleTrailing, this.actionLabel, this.onAction, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Container(
      decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.cardWeb), boxShadow: AppShadows.card),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) ...[
            Row(children: [
              Text(title!, style: AppText.title.withColor(LightModeColors.text)),
              if (titleTrailing != null) ...[const SizedBox(width: AppSpacing.sm), titleTrailing!],
              const Spacer(),
              if (actionLabel != null) InkWell(onTap: onAction, child: Text(actionLabel!, style: AppText.buttonLg.withColor(LightModeColors.bosco))),
            ]),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ]),
      ),
    ),
  );
}

/// 88 px zone banner with the user's region and the region selector link.
class RailZoneCard extends ConsumerWidget {
  const RailZoneCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final regions = ref.watch(regionsProvider(settings.countryCode ?? 'IT')).value ?? const [];
    final regionName = regions.where((region) => region.id == settings.regionId).firstOrNull?.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: HBMarketingImage(
        asset: 'assets/images/region_banner.jpg',
        height: 88,
        onTap: () => context.go(AppRoutes.huntingZone),
        overlayChild: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(regionName ?? 'home.rail_zone_empty'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: appFont(20, FontWeight.w600, spacing: -0.3, color: Colors.white)),
          const SizedBox(height: 2),
          Text('home.rail_zone_change'.tr(), style: AppText.ui.withColor(Colors.white)),
        ])),
      ),
    );
  }
}

/// Last 3 conversations. Hidden when there is none.
class RailMessagesCard extends ConsumerWidget {
  const RailMessagesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(recentConversationsProvider).value ?? const <Conversation>[];
    if (conversations.isEmpty) return const SizedBox.shrink();
    final me = ref.watch(authSessionProvider).value?.user.id;
    return RailCard(
      title: 'nav.messages'.tr(),
      actionLabel: 'home.rail_messages_all'.tr(),
      onAction: () => context.go(AppRoutes.messages),
      child: Column(children: [for (final item in conversations.take(3)) RailMessageRow(conversation: item, currentUserId: me)]),
    );
  }
}

class RailMessageRow extends StatelessWidget {
  final Conversation conversation;
  final String? currentUserId;

  const RailMessageRow({super.key, required this.conversation, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final name = conversation.displayName(currentUserId);
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;
    return InkWell(
      onTap: () => context.push(AppRoutes.conversationDetailPath(conversation.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HBAvatar(name: name, imageUrl: conversation.avatarUrl(currentUserId), size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.text)),
            if (last?.body.isNotEmpty == true) Text(last!.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(LightModeColors.textSecondary)),
          ])),
          const SizedBox(width: AppSpacing.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (last != null) Text(DateFormat.Hm().format(last.createdAt.toLocal()), style: AppText.caption.withColor(LightModeColors.textSecondary)),
            if (unread > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(width: 24, height: 24, alignment: Alignment.center, decoration: const BoxDecoration(color: LightModeColors.bosco, shape: BoxShape.circle), child: Text(unread > 9 ? '9+' : '$unread', style: appFont(12, FontWeight.w700, color: Colors.white))),
            ],
          ]),
        ]),
      ),
    );
  }
}

/// Up to 8 friends currently online, from the `online_friends(8)` RPC.
class RailOnlineCard extends ConsumerWidget {
  const RailOnlineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(onlineFriendsProvider(8)).value ?? const <OnlineFriend>[];
    if (friends.isEmpty) return const SizedBox.shrink();
    return RailCard(
      title: 'home.rail_online_title'.tr(),
      titleTrailing: Container(width: 10, height: 10, decoration: const BoxDecoration(color: LightModeColors.success, shape: BoxShape.circle)),
      actionLabel: 'common.see_all'.tr(),
      onAction: () => context.go(AppRoutes.people),
      child: Column(children: [for (final friend in friends) RailOnlineRow(friend: friend)]),
    );
  }
}

class RailOnlineRow extends StatelessWidget {
  final OnlineFriend friend;

  const RailOnlineRow({super.key, required this.friend});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: friend.username.isEmpty ? null : () => context.push(AppRoutes.publicProfilePath(friend.username)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        HBAvatar(name: friend.displayName, imageUrl: friend.avatarUrl, size: 36, showPresence: true),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(friend.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.withColor(LightModeColors.text))),
      ]),
    ),
  );
}

/// Three upcoming events with a date box, attendee stack and RSVP button.
class RailEventsCard extends ConsumerWidget {
  const RailEventsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(nearbyEventsProvider).value ?? const <HuntingEvent>[];
    if (events.isEmpty) return const SizedBox.shrink();
    return RailCard(
      title: 'home.rail_events_title'.tr(),
      actionLabel: 'common.see_all'.tr(),
      onAction: () => context.go(AppRoutes.events),
      child: Column(children: [for (final event in events.take(3)) RailEventRow(event: event)]),
    );
  }
}

class RailEventRow extends ConsumerWidget {
  final HuntingEvent event;

  const RailEventRow({super.key, required this.event});

  Future<void> _rsvp(BuildContext context, WidgetRef ref) async {
    if (ref.read(authSessionProvider).value == null) {
      context.push(AppRoutes.login);
      return;
    }
    try {
      await ref.read(eventRepositoryProvider).rsvp(event.id, 'going');
      ref.invalidate(myParticipationProvider(event.id));
      ref.invalidate(nearbyEventsProvider);
    } catch (_) {
      if (context.mounted) context.push(AppRoutes.eventDetailPath(event.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = event.startsAt.toLocal();
    final urgent = local.difference(DateTime.now()).inDays <= 7;
    final going = ref.watch(myParticipationProvider(event.id)).value?.status == 'going';
    final attendees = ref.watch(eventGoingPreviewProvider(event.id)).value ?? const <EventGoingPreview>[];
    return InkWell(
      onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 56, height: 64,
            decoration: BoxDecoration(color: urgent ? LightModeColors.dateUrgentBg : LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.media)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${local.day}', style: appFont(20, FontWeight.w700, color: urgent ? LightModeColors.dateUrgentText : LightModeColors.bosco)),
              Text(DateFormat.MMM(context.locale.languageCode).format(local).toUpperCase(), style: appFont(12, FontWeight.w600, color: urgent ? LightModeColors.dateUrgentText : LightModeColors.bosco)),
            ]),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.text)),
            if ((event.location ?? event.address ?? '').isNotEmpty) Text(event.location ?? event.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(LightModeColors.textSecondary)),
            if (attendees.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), RailAttendeeStack(attendees: attendees, total: event.participantCount)],
          ])),
          const SizedBox(width: AppSpacing.sm),
          RailRsvpButton(going: going, onTap: () => _rsvp(context, ref)),
        ]),
      ),
    );
  }
}

class RailAttendeeStack extends StatelessWidget {
  final List<EventGoingPreview> attendees;
  final int total;

  const RailAttendeeStack({super.key, required this.attendees, required this.total});

  @override
  Widget build(BuildContext context) {
    final visible = attendees.take(3).toList();
    final extra = total - visible.length;
    return Row(children: [
      SizedBox(
        width: 24 + (visible.length - 1) * 16,
        height: 24,
        child: Stack(children: [for (var index = 0; index < visible.length; index++) Positioned(left: index * 16, child: HBAvatar(name: visible[index].profile.displayName, imageUrl: visible[index].profile.avatarUrl, size: 24, ringColor: LightModeColors.surface, ringWidth: 1, singleInitial: true, initialsColor: LightModeColors.bosco, initialsFontSize: 10, initialsFontWeight: FontWeight.w600))]),
      ),
      if (extra > 0) ...[
        const SizedBox(width: AppSpacing.xs),
        Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2), decoration: BoxDecoration(color: LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text('+$extra', style: appFont(12, FontWeight.w600, color: LightModeColors.textSecondary))),
      ],
    ]);
  }
}

class RailRsvpButton extends StatelessWidget {
  final bool going;
  final VoidCallback onTap;

  const RailRsvpButton({super.key, required this.going, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: going ? LightModeColors.boscoSoft : LightModeColors.bosco,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: going ? null : onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(going ? 'events.attending_short'.tr() : 'events.going'.tr(), style: AppText.buttonSm.withColor(going ? LightModeColors.bosco : Colors.white)),
      ),
    ),
  );
}

/// Trending hashtags as 36 px outlined white chips.
class RailTrendingCard extends ConsumerWidget {
  const RailTrendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hashtags = ref.watch(trendingHashtagsProvider).value ?? const [];
    if (hashtags.isEmpty) return const SizedBox.shrink();
    return RailCard(
      title: 'home.rail_trending_title'.tr(),
      actionLabel: 'common.see_all'.tr(),
      onAction: () => context.go(AppRoutes.search),
      child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final item in hashtags) RailTrendChip(tag: item.tag, onTap: () => context.push(AppRoutes.tagPath(item.tag)))]),
    );
  }
}

class RailTrendChip extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;

  const RailTrendChip({super.key, required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: LightModeColors.surface,
    shape: const StadiumBorder(side: BorderSide(color: LightModeColors.border)),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Container(height: 36, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Text('#$tag', style: AppText.label.withColor(LightModeColors.text))),
    ),
  );
}

/// 176 px invite card at the bottom of the rail.
class RailInviteCard extends StatelessWidget {
  const RailInviteCard({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: HBMarketingImage(
      asset: 'assets/images/invite.jpg',
      height: 176,
      dimLeft: true,
      overlayChild: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('home.invite_title'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.title.withColor(Colors.white)),
            const SizedBox(height: AppSpacing.xs),
            Text('home.invite_message'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(Colors.white)),
          ]),
          Material(
            color: LightModeColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => context.go(AppRoutes.people),
              child: Container(height: 44, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.group_add_outlined, size: 20, color: LightModeColors.text),
                const SizedBox(width: AppSpacing.sm),
                Text('home.invite_cta'.tr(), style: AppText.buttonLg.withColor(LightModeColors.text)),
              ])),
            ),
          ),
        ]),
      ),
    ),
  );
}

/// Contextual explanation card some pages pass to the rail (PD3 contract).
class RailContextCard extends StatelessWidget {
  final String title;
  final String body;

  const RailContextCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => RailCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AppText.cardTitle.withColor(LightModeColors.text)),
    const SizedBox(height: AppSpacing.xs),
    Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(LightModeColors.textSecondary)),
  ]));
}
