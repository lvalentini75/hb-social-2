import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_price.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_placement.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});
  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  Position? _position;
  bool _locating = false;
  bool _denied = false;
  bool _cynology = false;

  void _create() => ref.read(authSessionProvider).value == null ? context.go(AppRoutes.login) : context.push(AppRoutes.eventCreate);

  Future<void> _locate() async {
    if (_locating || _position != null) return;
    setState(() { _locating = true; _denied = false; });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { if (mounted) setState(() => _denied = true); return; }
      final value = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _position = value);
    } catch (_) { if (mounted) setState(() => _denied = true); }
    finally { if (mounted) setState(() => _locating = false); }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(eventViewProvider);
    final selectedCategory = ref.watch(eventCategoryProvider);
    final categories = ref.watch(eventCategoriesProvider).value ?? const <EventCategory>[];
    final labels = ['events.category_all'.tr(), ...categories.map((item) => item.nameKey.tr())];
    final categoryIndex = selectedCategory == null ? 0 : categories.indexWhere((item) => item.slug == selectedCategory) + 1;
    final hasCynologyCategory = categories.any((item) => item.slug.contains('dog') || item.slug.contains('cyn'));
    if (view == EventView.nearby && _position == null && !_locating && !_denied) WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    return ListPageScaffold(
      title: 'events.title'.tr(), subtitle: 'events.subtitle'.tr(),
      action: compact ? null : HBButton.primary(label: 'events.create'.tr(), icon: Icons.add_rounded, onPressed: _create),
      filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(constraints: BoxConstraints(maxWidth: compact ? double.infinity : 420), child: HBSegmentedTabs(labels: ['events.view_upcoming'.tr(), 'events.view_past'.tr(), 'events.view_mine'.tr(), 'events.view_nearby'.tr()], selectedIndex: view.index, onChanged: (index) { ref.read(eventViewProvider.notifier).state = EventView.values[index]; ref.invalidate(eventsProvider); })),
        if (view != EventView.nearby) ...[const SizedBox(height: AppSpacing.md), HBFilterChipsRow(labels: labels, selectedIndex: categoryIndex < 0 ? 0 : categoryIndex, onChanged: (index) { ref.read(eventCategoryProvider.notifier).state = index == 0 ? null : categories[index - 1].slug; ref.invalidate(eventsProvider); })],
        if (view != EventView.nearby && !hasCynologyCategory) ...[const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerLeft, child: HBChip(label: 'dogs.events.filter'.tr(), selected: _cynology, icon: Icons.pets_outlined, onTap: () => setState(() => _cynology = !_cynology)))],
        if (view == EventView.nearby && _position != null) ...[const SizedBox(height: AppSpacing.md), HBFilterChipsRow(labels: const ['25 km', '50 km', '100 km', '250 km'], selectedIndex: const [25, 50, 100, 250].indexOf(ref.watch(nearbyRadiusProvider)), onChanged: (index) => ref.read(nearbyRadiusProvider.notifier).state = const [25, 50, 100, 250][index])],
        if (compact) ...[const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'events.create'.tr(), icon: Icons.add_rounded, onPressed: _create))],
      ]),
      body: view == EventView.nearby ? NearbyEventsBody(position: _position, locating: _locating, denied: _denied, onRetry: _locate) : EventsPagedBody(cynologyOnly: _cynology),
    );
  }
}

class EventsPagedBody extends ConsumerWidget {
  final bool cynologyOnly;
  const EventsPagedBody({super.key, this.cynologyOnly = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(eventsProvider).when(
    loading: () => const HBListSkeleton(count: 4),
    error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'events.error_title'.tr(), message: 'events.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(eventsProvider)))),
    data: (page) {
      final items = cynologyOnly ? page.items.where(_isCynologyEvent).toList() : page.items;
      if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.event_outlined, title: 'events.empty_title'.tr(), message: 'events.empty_message'.tr()));
      if (ref.watch(eventViewProvider) == EventView.mine) return MyEventsSections(events: page.items);
      return Column(children: [if (ref.watch(eventViewProvider) == EventView.upcoming) const EventFeaturedStrip(), for (var index = 0; index < items.length; index++) ...[EventListCard(event: items[index]), if (index == 1) const Padding(padding: EdgeInsets.only(top: AppSpacing.md), child: SponsoredPlacement(placement: AdPlacement.events)), if (index < items.length - 1) const SizedBox(height: AppSpacing.md)], if (page.hasMore) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: HBButton.secondary(label: 'notifications.load_more'.tr(), onPressed: page.isLoadingMore ? null : () => ref.read(eventsProvider.notifier).loadMore()))]);
    },
  );
}

class EventFeaturedStrip extends ConsumerWidget {
  const EventFeaturedStrip({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(deliveredAdsProvider(const AdPlacementRequest(AdPlacement.eventsTop, count: 4))).value ?? const <DeliveredAd>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.featured'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: ads.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (_, index) => SizedBox(width: 260, child: SponsoredCard(ad: ads[index], variant: AdPreviewVariant.tile))))]));
  }
}

bool _isCynologyEvent(HuntingEvent event) {
  final text = '${event.title} ${event.description ?? ''}'.toLowerCase();
  return event.category == 'meetup' || event.category.contains('dog') || event.category.contains('cyn') || RegExp(r'prova|raduno|cinofil').hasMatch(text);
}

class NearbyEventsBody extends ConsumerWidget {
  final Position? position;
  final bool locating;
  final bool denied;
  final VoidCallback onRetry;
  const NearbyEventsBody({super.key, required this.position, required this.locating, required this.denied, required this.onRetry});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locating) return HBCard(child: Column(children: [const LinearProgressIndicator(), const SizedBox(height: AppSpacing.md), Text('events.nearby_explanation'.tr())]));
    if (denied || position == null) return HBCard(child: HBEmptyState(icon: Icons.location_off_outlined, title: 'events.location_denied_title'.tr(), message: 'events.nearby_explanation'.tr(), action: HBButton.secondary(label: 'events.choose_region'.tr(), onPressed: () => context.push(AppRoutes.huntingZone))));
    final request = (latitude: position!.latitude, longitude: position!.longitude, radiusKm: ref.watch(nearbyRadiusProvider));
    return ref.watch(nearbyByLocationProvider(request)).when(loading: () => const HBListSkeleton(count: 4), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'events.error_title'.tr(), message: 'events.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry))), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.location_searching, title: 'events.nearby_empty'.tr(), message: 'events.empty_message'.tr())) : Column(children: [for (var index = 0; index < items.length; index++) ...[EventListCard(event: items[index]), if (index == 1) const Padding(padding: EdgeInsets.only(top: AppSpacing.md), child: SponsoredPlacement(placement: AdPlacement.events)), if (index < items.length - 1) const SizedBox(height: AppSpacing.md)]]));
  }
}

class MyEventsSections extends ConsumerWidget {
  final List<HuntingEvent> events;
  const MyEventsSections({super.key, required this.events});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organized = events.where((event) => ref.watch(eventCanManageProvider(event)).value ?? false).toList();
    final tickets = events.where((event) => !organized.contains(event)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('events.my_tickets'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md),
      if (tickets.isEmpty) HBCard(child: HBEmptyState(icon: Icons.confirmation_number_outlined, title: 'events.my_tickets_empty'.tr(), message: 'events.empty_message'.tr())) else for (final event in tickets) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: EventListCard(event: event)),
      const SizedBox(height: AppSpacing.lg), Text('events.organized_by_me'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md),
      if (organized.isEmpty) HBCard(child: HBEmptyState(icon: Icons.event_note_outlined, title: 'events.organized_empty'.tr(), message: 'events.empty_message'.tr())) else for (final event in organized) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: EventListCard(event: event)),
    ]);
  }
}

/// PD4b event card: 160 px cover inside the 12 px padding, overlay category
/// chip, 48x56 date box overlapping the cover, title, place, the participants
/// avatar stack and the RSVP action.
class EventListCard extends ConsumerWidget {
  final HuntingEvent event;
  const EventListCard({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participation = ref.watch(myParticipationProvider(event.id)).value;
    final date = event.startsAt.toLocal();
    final going = const {'going', 'checked_in'}.contains(participation?.status);
    final previews = event.participantCount == 0 ? const <EventGoingPreview>[] : ref.watch(eventGoingPreviewProvider(event.id)).value ?? const <EventGoingPreview>[];
    return HBCard(
      radius: AppRadius.cardWeb,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          ClipRRect(borderRadius: BorderRadius.circular(AppRadius.media), child: SizedBox(height: 160, width: double.infinity, child: event.coverUrl?.isNotEmpty == true
              ? Image.network(event.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.event_rounded, color: LightModeColors.bosco, size: 28)))
              : const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.event_rounded, color: LightModeColors.bosco, size: 28)))),
          Positioned(top: 8, right: 8, child: Container(height: 28, padding: const EdgeInsets.symmetric(horizontal: 10), alignment: Alignment.center, decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text('events.category.${event.category}'.tr(), style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.text)))),
          Positioned(left: 8, bottom: -8, child: EventDateBlock(date: date)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.cardTitle.withColor(LightModeColors.text)),
        const SizedBox(height: 4),
        Text([event.location ?? 'common.unavailable'.tr(), DateFormat.jm(context.locale.toLanguageTag()).format(date), if (event.distanceKm != null) 'events.distance'.tr(namedArgs: {'km': event.distanceKm!.toStringAsFixed(1)})].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(LightModeColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          if (previews.isNotEmpty) Expanded(child: EventAvatarStack(items: previews, total: event.participantCount)) else const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          if (event.priceMinor > 0) ...[HBPrice(amountMinor: event.priceMinor, currencyCode: event.currencyCode), const SizedBox(width: AppSpacing.sm)],
          EventCardAction(label: going ? 'events.attending_short'.tr() : 'events.going'.tr(), active: going, onTap: () => context.push(AppRoutes.eventDetailPath(event.id))),
        ]),
        if (event.isFull || participation?.status == 'waitlist' || event.status != 'published') ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
            if (event.isFull) HBStatusChip(kind: HBStatusKind.pending, label: 'events.sold_out'.tr()),
            if (participation?.status == 'waitlist') HBStatusChip(kind: HBStatusKind.pending, label: 'events.waitlisted_short'.tr()),
            if (event.status != 'published') HBStatusChip(kind: event.status == 'cancelled' ? HBStatusKind.rejected : HBStatusKind.neutral, label: 'events.status.${event.status}'.tr()),
          ]),
        ],
      ]),
    );
  }
}

class EventCardAction extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const EventCardAction({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: active ? LightModeColors.boscoSoft : LightModeColors.bosco,
    shape: const StadiumBorder(),
    child: InkWell(borderRadius: BorderRadius.circular(AppRadius.pill), onTap: onTap, child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), alignment: Alignment.center, child: Text(label, style: AppText.buttonSm.withColor(active ? LightModeColors.bosco : Colors.white)))),
  );
}

/// Overlapping 24 px avatars of real participants with the remaining "+N".
class EventAvatarStack extends StatelessWidget {
  final List<EventGoingPreview> items;
  final int total;
  const EventAvatarStack({super.key, required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 24 + (shown.length - 1) * 17, height: 24, child: Stack(children: [for (var index = 0; index < shown.length; index++) Positioned(left: index * 17, child: HBAvatar(name: shown[index].profile.displayName, imageUrl: shown[index].profile.avatarUrl, size: 24, ringColor: Colors.white))])),
      if (total > shown.length) ...[const SizedBox(width: 6), Text('+${total - shown.length}', style: AppText.small.withColor(LightModeColors.textSecondary))],
    ]);
  }
}

/// 48x56 date box. Events within 7 days use the urgent palette.
class EventDateBlock extends StatelessWidget {
  final DateTime? date;
  final double width;
  final double height;
  const EventDateBlock({super.key, required this.date, this.width = 48, this.height = 56});

  @override
  Widget build(BuildContext context) {
    final urgent = date != null && date!.difference(DateTime.now()).inDays < 7 && date!.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final background = urgent ? LightModeColors.dateUrgentBg : LightModeColors.surfaceSoft;
    final foreground = urgent ? LightModeColors.dateUrgentText : LightModeColors.bosco;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(date == null ? '-' : '${date!.day}', style: appFont(18, FontWeight.w700, height: 1.1).withColor(foreground)),
        Text(date == null ? 'common.unavailable'.tr() : DateFormat.MMM(context.locale.toLanguageTag()).format(date!).toUpperCase(), style: appFont(11, FontWeight.w600, height: 1.1).withColor(foreground)),
      ]),
    );
  }
}