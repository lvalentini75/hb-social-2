import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/utils/geo.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_price.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/translatable_text.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/presentation/event_map.dart';
import 'package:hb_social/features/events/presentation/events_page.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';
import 'package:hb_social/features/weather/presentation/event_weather_tile.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_tag_selector.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/ads/presentation/boost_sheet.dart';
import 'package:hb_social/core/services/seo_service.dart';

class EventDetailPage extends ConsumerWidget {
  final String eventId;
  final bool debugPreview;
  const EventDetailPage({super.key, required this.eventId, this.debugPreview = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(eventByIdProvider(eventId)).when(
    loading: () => const PageColumns(center: Center(child: CircularProgressIndicator())),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'events.error_title'.tr(), message: 'events.error_message'.tr()))),
    data: (event) { if (event == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.event_busy_outlined, title: 'events.not_found_title'.tr(), message: 'events.not_found_message'.tr()))); SeoService.update(title: '${event.title} - HB Social', description: 'seo.event_description'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).format(event.startsAt.toLocal()), 'place': event.location ?? ''}), path: AppRoutes.eventDetailPath(event.id), imageUrl: event.coverUrl); return EventDetailBody(event: event); },
  );
}

class EventDetailBody extends ConsumerStatefulWidget {
  final HuntingEvent event;
  const EventDetailBody({super.key, required this.event});
  @override
  ConsumerState<EventDetailBody> createState() => _EventDetailBodyState();
}

class _EventDetailBodyState extends ConsumerState<EventDetailBody> {
  EventParticipation? _participation;
  bool _working = false;
  int _tabIndex = 0;
  double? _distance;
  final Set<String> _participatingDogIds = {};

  Future<void> _selectDogs() async {
    final dogs = (ref.read(myDogsProvider).value ?? const <Dog>[]).where((dog) => dog.status == DogStatus.active).toList();
    if (dogs.isEmpty) return;
    final value = await showModalBottomSheet<Set<String>>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => DogTagSelector(dogs: dogs, selectedIds: _participatingDogIds));
    if (value != null && mounted) setState(() { _participatingDogIds.clear(); _participatingDogIds.addAll(value); });
  }

  Future<void> _rsvp(String status) async {
    if (ref.read(authSessionProvider).value == null) { context.go(AppRoutes.login); return; }
    setState(() => _working = true);
    try {
      final value = await ref.read(eventRepositoryProvider).rsvp(widget.event.id, status);
      if (mounted) setState(() => _participation = value);
      ref.invalidate(myParticipationProvider(widget.event.id)); ref.invalidate(eventByIdProvider(widget.event.id)); ref.invalidate(eventGoingPreviewProvider(widget.event.id)); ref.invalidate(eventsProvider);
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _calculateDistance() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('events.location_denied');
      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _distance = distanceKm(position.latitude, position.longitude, widget.event.latitude!, widget.event.longitude!));
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _setStatus(String status) async {
    final cancel = status == 'cancelled';
    final confirmed = await showDialog<bool>(context: context, builder: (_) => EventStatusConfirmation(titleKey: cancel ? 'events.cancel_title' : 'events.publish_title', messageKey: cancel ? 'events.cancel_message' : 'events.publish_message', actionKey: cancel ? 'events.cancel_event' : 'events.publish')) ?? false;
    if (!confirmed) return;
    try { await ref.read(eventRepositoryProvider).setEventStatus(widget.event.id, status); ref.invalidate(eventByIdProvider(widget.event.id)); ref.invalidate(eventsProvider); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  void _openOrganizer() {
    final organizer = widget.event.organizer;
    if (organizer.kind == 'user' && organizer.username != null) context.push(AppRoutes.publicProfilePath(organizer.username!));
    if (organizer.kind == 'page' && organizer.slug != null) context.push(AppRoutes.pageDetailPath(organizer.slug!));
    if (organizer.kind == 'group' && organizer.slug != null) context.push(AppRoutes.groupDetailPath(organizer.slug!));
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final backendParticipation = ref.watch(myParticipationProvider(event.id)).value;
    final participation = _participation ?? backendParticipation;
    final canManage = ref.watch(eventCanManageProvider(event)).value ?? false;
    final previews = ref.watch(eventGoingPreviewProvider(event.id));
    final disabled = event.status == 'cancelled' || event.isPastForRsvp;
    final going = const {'going', 'checked_in'}.contains(participation?.status);
    final interested = participation?.status == 'interested';
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    return PageColumns(gutter: false, center: CustomScrollView(slivers: [SliverList.list(children: [
      if (event.status != 'published') Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0), child: EventStateBanner(status: event.status)),
      EventHero(event: event, interested: interested, canManage: canManage, onToggleInterest: () => _rsvp(interested ? 'cancelled' : 'interested'), onEdit: () => context.push(AppRoutes.eventEditPath(event.id)), onCancel: () => _setStatus('cancelled'), onPublish: () => _setStatus('published')),
      Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Flexible(child: TranslatableText(type: 'event', id: event.id, field: 'title', text: event.title, style: AppText.heading.withColor(LightModeColors.text))),
          const SizedBox(width: AppSpacing.sm),
          HBChip(label: 'events.category.${event.category}'.tr(), tag: true),
        ]),
        const SizedBox(height: 6),
        Text(event.location ?? event.address ?? 'common.unavailable'.tr(), style: AppText.ui.withColor(LightModeColors.textSecondary)),
        if (canManage) ...[const SizedBox(height: AppSpacing.sm), Row(children: [BoostStatusControl(targetType: 'event', targetId: event.id), const Spacer(), if (event.status == 'published' && event.startsAt.isAfter(DateTime.now().toUtc())) HBButton.soft(label: 'boost.action'.tr(), icon: Icons.rocket_launch_outlined, onPressed: () => showBoostSheet(context, targetType: 'event', targetId: event.id))])],
        const SizedBox(height: AppSpacing.md),
        InkWell(onTap: _openOrganizer, borderRadius: BorderRadius.circular(AppRadius.inner), child: Row(children: [
          HBAvatar(name: event.organizer.name, imageUrl: event.organizer.avatarUrl, size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.organizer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.buttonLg.withColor(LightModeColors.text)),
            Text('events.organizer_label'.tr(), style: AppText.caption.withColor(LightModeColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 18, color: LightModeColors.textSecondary),
        ])),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, thickness: 1, color: LightModeColors.divider),
        EventStatsRow(event: event, onShowParticipants: () => setState(() => _tabIndex = 1)),
        const Divider(height: 1, thickness: 1, color: LightModeColors.divider),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: EventDetailAction(label: going ? 'events.attending_short'.tr() : 'events.going'.tr(), filled: !going, outlined: false, onTap: disabled || _working ? null : () => _rsvp('going'))),
          const SizedBox(width: 12),
          Expanded(child: EventDetailAction(label: 'events.interested_action'.tr(), filled: false, outlined: interested, onTap: disabled || _working ? null : () => _rsvp(interested ? 'cancelled' : 'interested'))),
        ]),
        if (disabled) ...[const SizedBox(height: AppSpacing.sm), Text((event.status == 'cancelled' ? 'events.rsvp_cancelled' : 'events.rsvp_closed').tr(), style: AppText.label.withColor(LightModeColors.textSecondary))],
        if (event.status == 'cancelled' && event.priceMinor > 0) ...[const SizedBox(height: AppSpacing.sm), Text('p34b.cancelled_refund_note'.tr(), style: AppText.label.withColor(LightModeColors.textSecondary))],
        const SizedBox(height: AppSpacing.md),
        EventParticipationCard(event: event),
        const SizedBox(height: AppSpacing.md),
        HBSegmentedTabs(variant: HBSegmentedTabsVariant.underlined, labels: ['events.tab_details'.tr(), 'events.tab_participants'.tr(), 'events.tab_discussion'.tr()], selectedIndex: _tabIndex, onChanged: (index) => setState(() => _tabIndex = index)),
        const SizedBox(height: AppSpacing.md),
      ])),
      if (_tabIndex == 0) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EventInfoRow(icon: Icons.schedule_outlined, label: 'events.when'.tr(), value: DateFormat.yMMMMd(context.locale.toLanguageTag()).add_jm().format(event.startsAt.toLocal())),
        EventInfoRow(icon: Icons.location_on_outlined, label: 'events.where'.tr(), value: event.location ?? event.address ?? 'common.unavailable'.tr(), action: event.latitude == null || event.longitude == null ? null : EventMapLink(onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${event.latitude},${event.longitude}'), mode: LaunchMode.externalApplication))),
        EventInfoRow(icon: Icons.local_offer_outlined, label: 'events.category_label'.tr(), value: '${'events.category.${event.category}'.tr()} · ${'events.title'.tr()}'),
        EventInfoRow(icon: Icons.person_outline_rounded, label: 'events.form.organizer'.tr(), value: event.organizer.name),
        if (event.description?.trim().isNotEmpty == true) EventInfoRow(icon: Icons.notes_rounded, label: 'events.description_title'.tr(), valueWidget: TranslatableText(type: 'event', id: event.id, field: 'description', text: event.description!.trim())),
        if (participation != null) ...[const SizedBox(height: AppSpacing.md), EventTicketState(event: event, participation: participation)],
        if (participation != null && (ref.watch(myDogsProvider).value ?? const <Dog>[]).where((dog) => dog.status == DogStatus.active).isNotEmpty) ...[const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBButton.soft(label: 'dogs.events.attend_with'.tr(), icon: Icons.pets_outlined, onPressed: _selectDogs), if (_participatingDogIds.isNotEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final dog in (ref.watch(myDogsProvider).value ?? const <Dog>[]).where((dog) => _participatingDogIds.contains(dog.id))) HBChip(label: dog.name, selected: true)])), const SizedBox(height: AppSpacing.xs), Text('dogs.events.local_note'.tr(), style: AppText.label.withColor(LightModeColors.textSecondary))]))],
        if (event.latitude != null && event.longitude != null && event.startsAt.isAfter(DateTime.now().subtract(const Duration(days: 1))) && event.startsAt.isBefore(DateTime.now().add(const Duration(days: 7)))) ...[const SizedBox(height: AppSpacing.md), EventWeatherTile(event: event)],
        if (event.latitude != null && event.longitude != null) ...[const SizedBox(height: AppSpacing.md), HBCard.media(child: EventMap(latitude: event.latitude!, longitude: event.longitude!)), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: 'events.directions'.tr(), icon: Icons.directions_outlined, onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${event.latitude},${event.longitude}'), mode: LaunchMode.externalApplication)), HBButton.ghost(label: 'events.copy_address'.tr(), icon: Icons.copy_rounded, onPressed: event.address == null ? null : () async { await Clipboard.setData(ClipboardData(text: event.address!)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('events.address_copied'.tr()))); }), HBButton.soft(label: 'events.calculate_distance'.tr(), onPressed: _calculateDistance)]), if (_distance != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('events.distance_from_you'.tr(namedArgs: {'km': _distance!.toStringAsFixed(1)}), style: AppText.label.withColor(LightModeColors.textSecondary)))],
        if (canManage) ...[const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'events.manage'.tr(), icon: Icons.tune_rounded, onPressed: () => context.push(AppRoutes.eventManagePath(event.id)))],
      ])),
      if (_tabIndex == 1) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EventCapacity(event: event),
        const SizedBox(height: AppSpacing.md),
        previews.when(loading: () => const LinearProgressIndicator(), error: (_, __) => const SizedBox.shrink(), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.group_outlined, title: 'event_manage.participants_empty'.tr(), message: 'event_manage.list_empty_message'.tr()) : EventGoingAvatars(items: items, total: event.participantCount)),
      ]))),
      if (_tabIndex == 2) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'events.discussion_empty_title'.tr(), message: 'events.discussion_empty_message'.tr()))),
      SizedBox(height: compact ? 96 : AppSpacing.xl),
    ])]));
  }
}

/// Edge-to-edge event cover with the round overlay controls and the 96x112
/// date box overlapping its bottom edge (PD4b, mockup 1 / screen 4).
class EventHero extends StatelessWidget {
  final HuntingEvent event;
  final bool interested;
  final bool canManage;
  final VoidCallback onToggleInterest;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onPublish;

  const EventHero({super.key, required this.event, required this.interested, required this.canManage, required this.onToggleInterest, required this.onEdit, required this.onCancel, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final height = compact ? 360.0 : 320.0;
    final date = event.startsAt.toLocal();
    final locale = context.locale.toLanguageTag();
    final cover = event.coverUrl?.isNotEmpty == true
        ? Image.network(event.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.bosco))
        : const ColoredBox(color: LightModeColors.bosco);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 0 : AppSpacing.md, compact ? 0 : AppSpacing.md, compact ? 0 : AppSpacing.md, 40),
      child: Stack(clipBehavior: Clip.none, children: [
        compact ? SizedBox(height: height, width: double.infinity, child: cover) : ClipRRect(borderRadius: BorderRadius.circular(AppRadius.cardWeb), child: SizedBox(height: height, width: double.infinity, child: cover)),
        Positioned(left: AppSpacing.md, top: AppSpacing.md, child: EventRoundButton(icon: Icons.arrow_back_rounded, size: 40, onTap: () => context.pop())),
        Positioned(right: AppSpacing.md, top: AppSpacing.md, child: Row(children: [
          EventRoundButton(icon: Icons.ios_share_rounded, size: 40, onTap: () => Clipboard.setData(ClipboardData(text: Uri.base.resolve(AppRoutes.eventDetailPath(event.id)).toString()))),
          const SizedBox(width: AppSpacing.sm),
          if (canManage) PopupMenuButton<String>(
            tooltip: 'events.manage'.tr(),
            onSelected: (value) { if (value == 'edit') onEdit(); if (value == 'cancel') onCancel(); if (value == 'publish') onPublish(); },
            itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('events.edit'.tr())), if (event.status == 'draft') PopupMenuItem(value: 'publish', child: Text('events.publish'.tr())), if (event.status != 'cancelled') PopupMenuItem(value: 'cancel', child: Text('events.cancel_event'.tr()))],
            child: const EventRoundButton(icon: Icons.more_horiz_rounded, size: 40, onTap: null),
          ) else EventRoundButton(icon: Icons.more_horiz_rounded, size: 40, onTap: () {}),
        ])),
        Positioned(right: AppSpacing.md, top: 120, child: EventRoundButton(icon: interested ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 48, foreground: interested ? LightModeColors.danger : LightModeColors.text, onTap: onToggleInterest)),
        Positioned(left: AppSpacing.md, bottom: -40, child: Container(
          width: 96,
          height: 112,
          decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.cardWeb), boxShadow: AppShadows.card),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat.E(locale).format(date).toUpperCase(), style: appFont(12, FontWeight.w600, height: 1.1).withColor(LightModeColors.bosco)),
            Text('${date.day}', style: AppText.display.withColor(LightModeColors.text)),
            Text(DateFormat.MMM(locale).format(date).toUpperCase(), style: appFont(12, FontWeight.w600, height: 1.1).withColor(LightModeColors.bosco)),
          ]),
        )),
      ]),
    );
  }
}

class EventRoundButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color foreground;
  final VoidCallback? onTap;
  const EventRoundButton({super.key, required this.icon, required this.size, this.foreground = LightModeColors.text, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: LightModeColors.surface,
    shape: const CircleBorder(),
    child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: size, height: size, child: Icon(icon, size: size * .45, color: foreground))),
  );
}

/// Two cells divided by a vertical divider: real going and interested counts.
class EventStatsRow extends StatelessWidget {
  final HuntingEvent event;
  final VoidCallback onShowParticipants;
  const EventStatsRow({super.key, required this.event, required this.onShowParticipants});

  @override
  Widget build(BuildContext context) => SizedBox(height: 56, child: Row(children: [
    Expanded(child: InkWell(onTap: onShowParticipants, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.groups_2_outlined, size: 20, color: LightModeColors.textSecondary),
      const SizedBox(width: AppSpacing.sm),
      Flexible(child: Text('events.going_count'.tr(namedArgs: {'n': '${event.participantCount}'}), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.withColor(LightModeColors.text))),
      const SizedBox(width: 6),
      const Icon(Icons.info_outline_rounded, size: 18, color: LightModeColors.textTertiary),
    ]))),
    const VerticalDivider(width: 1, thickness: 1, color: LightModeColors.divider),
    Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.favorite_rounded, size: 20, color: LightModeColors.danger),
      const SizedBox(width: AppSpacing.sm),
      Flexible(child: Text('events.interested_count'.tr(namedArgs: {'n': '${event.interestedCount}'}), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.withColor(LightModeColors.text))),
    ])),
  ]));
}

class EventDetailAction extends StatelessWidget {
  final String label;
  final bool filled;
  final bool outlined;
  final VoidCallback? onTap;
  const EventDetailAction({super.key, required this.label, required this.filled, required this.outlined, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? LightModeColors.bosco : LightModeColors.boscoSoft,
    shape: StadiumBorder(side: outlined ? const BorderSide(color: LightModeColors.bosco, width: 1.5) : BorderSide.none),
    child: InkWell(borderRadius: BorderRadius.circular(AppRadius.pill), onTap: onTap, child: Container(height: 52, alignment: Alignment.center, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.buttonLg.withColor(filled ? Colors.white : LightModeColors.bosco)))),
  );
}

/// boscoSoft info card: free participation or ticket price and seats.
class EventParticipationCard extends StatelessWidget {
  final HuntingEvent event;
  const EventParticipationCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final free = event.priceMinor == 0;
    final title = free ? 'events.free_participation'.tr() : 'events.ticket_price'.tr(namedArgs: {'price': MoneyFormatter.format(amountMinor: event.priceMinor, currencyCode: event.currencyCode, locale: context.locale)});
    final message = free
        ? 'events.free_participation_help'.tr()
        : event.capacity == null ? 'events.ticket_price_help'.tr() : 'events.seats_available'.tr(namedArgs: {'n': '${event.capacity! - event.participantCount < 0 ? 0 : event.capacity! - event.participantCount}'});
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: LightModeColors.boscoSoft, borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.calendar_today_rounded, size: 24, color: LightModeColors.bosco),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.buttonLg.withColor(LightModeColors.text)),
          const SizedBox(height: 2),
          Text(message, style: appFont(14, FontWeight.w400, height: 1.4).withColor(LightModeColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class EventMapLink extends StatelessWidget {
  final VoidCallback onTap;
  const EventMapLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Text('events.show_map'.tr(), style: AppText.buttonLg.withColor(LightModeColors.bosco)));
}

class EventStateBanner extends StatelessWidget {
  final String status;
  const EventStateBanner({super.key, required this.status});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: status == 'cancelled' ? LightModeColors.lightError.withValues(alpha: 0.1) : LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [Icon(status == 'cancelled' ? Icons.event_busy_outlined : Icons.edit_calendar_outlined), const SizedBox(width: AppSpacing.sm), Text('events.banner.$status'.tr(), style: context.textStyles.titleSmall)]));
}

class EventCapacity extends StatelessWidget {
  final HuntingEvent event;
  const EventCapacity({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final text = event.capacity == null ? 'events.counts_no_capacity'.tr(namedArgs: {'going': '${event.participantCount}', 'interested': '${event.interestedCount}'}) : 'events.counts'.tr(namedArgs: {'going': '${event.participantCount}', 'interested': '${event.interestedCount}', 'capacity': '${event.capacity}'});
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), if (event.capacity != null) ...[const SizedBox(height: AppSpacing.sm), LinearProgressIndicator(value: (event.participantCount / event.capacity!).clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(AppRadius.pill), color: event.isFull ? LightModeColors.lightWarning : LightModeColors.lightPrimary, backgroundColor: LightModeColors.lightBackgroundSoft)]]);
  }
}

class EventGoingAvatars extends StatelessWidget {
  final List<EventGoingPreview> items;
  final int total;
  const EventGoingAvatars({super.key, required this.items, required this.total});
  @override
  Widget build(BuildContext context) => Row(children: [SizedBox(width: items.isEmpty ? 0 : 28 + (items.length - 1) * 24, height: 38, child: Stack(children: [for (var index = 0; index < items.length; index++) Positioned(left: index * 24, child: HBAvatar(name: items[index].profile.displayName, imageUrl: items[index].profile.avatarUrl, size: 36, ringColor: items[index].isFriend ? LightModeColors.lightPrimary : LightModeColors.lightSurface))])), if (total > items.length) ...[const SizedBox(width: AppSpacing.sm), Text('+${total - items.length}')]]);
}

class EventRsvpActions extends StatelessWidget {
  final HuntingEvent event;
  final EventParticipation? participation;
  final bool disabled;
  final bool working;
  final ValueChanged<String> onRsvp;
  const EventRsvpActions({super.key, required this.event, required this.participation, required this.disabled, required this.working, required this.onRsvp});
  @override
  Widget build(BuildContext context) {
    if (participation?.status == 'checked_in') return HBStatusChip(kind: HBStatusKind.approved, label: 'events.checked_in'.tr());
    if (participation?.status == 'going') return Row(children: [HBStatusChip(kind: HBStatusKind.approved, label: 'events.attending'.tr()), PopupMenuButton<String>(onSelected: onRsvp, itemBuilder: (_) => [PopupMenuItem(value: 'cancelled', child: Text('events.not_attending'.tr()))])]);
    if (participation?.status == 'waitlist') return Row(children: [HBStatusChip(kind: HBStatusKind.pending, label: participation?.waitlistPosition == null ? 'events.waitlisted_short'.tr() : 'events.waitlisted'.tr(namedArgs: {'position': '${participation!.waitlistPosition}'})), PopupMenuButton<String>(onSelected: onRsvp, itemBuilder: (_) => [PopupMenuItem(value: 'cancelled', child: Text('events.leave_waitlist'.tr()))])]);
    if (participation?.status == 'interested') return Row(children: [HBStatusChip(kind: HBStatusKind.info, label: 'events.interested'.tr()), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'events.going'.tr(), onPressed: disabled || working ? null : () => onRsvp('going'))]);
    return Row(children: [Expanded(child: HBButton.primary(label: 'events.going'.tr(), onPressed: disabled || working ? null : () => onRsvp('going'), isLoading: working, size: HBButtonSize.lg)), const SizedBox(width: 12), Expanded(child: HBButton.soft(label: 'events.interested_action'.tr(), onPressed: disabled || working ? null : () => onRsvp('interested'), size: HBButtonSize.lg))]);
  }
}

class EventTicketState extends ConsumerStatefulWidget {
  final HuntingEvent event;
  final EventParticipation participation;
  const EventTicketState({super.key, required this.event, required this.participation});
  @override ConsumerState<EventTicketState> createState() => _EventTicketStateState();
}

class _EventTicketStateState extends ConsumerState<EventTicketState> {
  bool paying = false;
  Future<void> pay() async {
    setState(() => paying = true);
    try {
      final base = Uri.base;
      final result = await ref.read(paymentsRepositoryProvider).eventCheckout(eventId: widget.event.id, successUrl: base.resolve('/orders/{ORDER_ID}?checkout=success').toString(), cancelUrl: base.resolve('/events/${widget.event.id}').toString());
      await launchUrl(result.url, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication, webOnlyWindowName: kIsWeb ? '_self' : null);
    } on AppException catch (error) {
      if (!mounted) return;
      final key = error.messageKey.endsWith('order_seller_not_onboarded') ? 'p34b.organizer_cash_only' : error.messageKey;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr(namedArgs: error.namedArgs))));
    } finally { if (mounted) setState(() => paying = false); }
  }
  @override
  Widget build(BuildContext context) {
    final event = widget.event; final participation = widget.participation;
    if (participation.paymentStatus == 'refunded') return HBCard(child: Text('events.ticket_refunded'.tr()));
    if (event.priceMinor > 0 && participation.status == 'going' && participation.paymentStatus == 'pending') return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('events.ticket_after_payment'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'p34b.pay_ticket'.tr(namedArgs: {'price': MoneyFormatter.format(amountMinor: event.priceMinor, currencyCode: event.currencyCode, locale: context.locale)}), isLoading: paying, onPressed: paying ? null : pay))]));
    if (!const {'going', 'checked_in'}.contains(participation.status) || participation.ticketCode == null) return const SizedBox.shrink();
    return EventTicketCard(event: event, participation: participation, fullscreenButton: true);
  }
}

class EventTicketCard extends StatelessWidget {
  final HuntingEvent event;
  final EventParticipation participation;
  final bool fullscreenButton;
  const EventTicketCard({super.key, required this.event, required this.participation, this.fullscreenButton = false});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(children: [Text('events.ticket_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), QrImageView(data: 'hb:ticket:${participation.ticketCode}', size: 210, backgroundColor: LightModeColors.lightSurface), const SizedBox(height: AppSpacing.sm), SelectableText(participation.ticketCode!, style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), Text(event.title, textAlign: TextAlign.center, style: context.textStyles.titleMedium), Text(DateFormat.yMMMMd(context.locale.toLanguageTag()).add_jm().format(event.startsAt.toLocal()), textAlign: TextAlign.center), const SizedBox(height: AppSpacing.sm), Text('events.show_at_entrance'.tr()), if (fullscreenButton) ...[const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'events.fullscreen'.tr(), icon: Icons.fullscreen_rounded, onPressed: () => context.push(AppRoutes.eventTicketPath(event.id)))]]));
}

class EventTicketPage extends ConsumerWidget {
  final String eventId;
  const EventTicketPage({super.key, required this.eventId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId)); final participation = ref.watch(myParticipationProvider(eventId));
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl), sliver: SliverToBoxAdapter(child: event.value == null || participation.value?.ticketCode == null ? HBCard(child: HBEmptyState(icon: Icons.qr_code_2, title: 'events.ticket_unavailable'.tr(), message: 'events.ticket_after_payment'.tr())) : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: EventTicketCard(event: event.value!, participation: participation.value!)))))]));
  }
}

/// PD4b detail row: 20 px monochrome icon, 110 px secondary label and the
/// value on the left, with an optional inline action below it.
class EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Widget? action;
  const EventInfoRow({super.key, required this.icon, required this.label, this.value, this.valueWidget, this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: LightModeColors.textSecondary),
      const SizedBox(width: 12),
      SizedBox(width: 110, child: Text(label, maxLines: 2, style: AppText.label.withColor(LightModeColors.textSecondary))),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        valueWidget ?? Text(value ?? 'common.unavailable'.tr(), style: AppText.ui.withColor(LightModeColors.text)),
        if (action != null) ...[const SizedBox(height: 4), action!],
      ])),
    ]),
  );
}