import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  void _create(BuildContext context) => showComingSoonInfo(context, icon: Icons.event_outlined, title: 'common.coming_soon_title'.tr(), message: 'events.create_soon'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(eventViewProvider);
    final category = ref.watch(eventCategoryProvider);
    final events = ref.watch(eventsProvider);
    return ListPageScaffold(
      title: 'events.title'.tr(),
      subtitle: 'events.subtitle'.tr(),
      action: HBButton.primary(label: 'events.create'.tr(), icon: Icons.add_rounded, onPressed: () => _create(context)),
      filters: Column(children: [
        HBSegmentedTabs(labels: ['events.view_upcoming'.tr(), 'events.view_past'.tr(), 'events.view_mine'.tr()], selectedIndex: view, onChanged: (index) => ref.read(eventViewProvider.notifier).state = index),
        const SizedBox(height: AppSpacing.md),
        HBFilterChipsRow(labels: EventCategory.values.map((item) => item.translationKey.tr()).toList(), selectedIndex: category.index, onChanged: (index) => ref.read(eventCategoryProvider.notifier).state = EventCategory.values[index]),
      ]),
      body: events.when(
        loading: () => const EventsListSkeleton(),
        error: (error, stack) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'events.error_title'.tr(), message: 'events.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(eventsProvider)))),
        data: (items) => items.isEmpty
            ? HBCard(child: HBEmptyState(icon: Icons.event_outlined, title: 'events.empty_title'.tr(), message: 'events.empty_message'.tr(), action: HBButton.primary(label: 'events.empty_cta'.tr(), onPressed: () => _create(context))))
            : Column(children: items.map((event) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: EventListCard(event: event))).toList()),
      ),
      rail: Column(children: [
        PageRailCard(label: 'events.calendar_title'.tr(), child: const MiniCalendar()),
        const SizedBox(height: AppSpacing.md),
        PageRailCard(label: 'events.nearby_title'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('events.nearby_empty'.tr()), const SizedBox(height: AppSpacing.md), HBButton.soft(label: 'events.set_zone'.tr(), onPressed: () => context.go(AppRoutes.hunting))])),
      ]),
    );
  }
}

class EventListCard extends StatelessWidget {
  final HuntingEvent event;

  const EventListCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final date = event.startsAt?.toLocal();
    return GestureDetector(
      onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
      child: HBCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          EventDateBlock(date: date),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('${event.location ?? '—'} · ${date == null ? '—' : DateFormat.jm(context.locale.toLanguageTag()).format(date)} · ${'events.participant_count'.tr(namedArgs: {'count': '${event.participantCount}'})}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
          ])),
          const SizedBox(width: AppSpacing.sm),
          HBStatusChip(kind: event.costMinor == 0 ? HBStatusKind.approved : HBStatusKind.neutral, label: event.costMinor == null ? '—' : (event.costMinor == 0 ? 'events.free'.tr() : 'events.paid'.tr())),
        ]),
      ),
    );
  }
}

class EventDateBlock extends StatelessWidget {
  final DateTime? date;
  final double size;

  const EventDateBlock({super.key, required this.date, this.size = 56});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(date == null ? '—' : DateFormat.MMM(context.locale.toLanguageTag()).format(date!).toUpperCase(), style: context.textStyles.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: LightModeColors.lightForest)),
      Text(date == null ? '—' : '${date!.day}', style: context.textStyles.titleLarge?.copyWith(fontSize: size >= 70 ? 26 : 20, fontWeight: FontWeight.w700, color: LightModeColors.lightForest)),
    ]),
  );
}

class EventsListSkeleton extends StatelessWidget {
  const EventsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: HBCard(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            HBSkeleton(width: 56, height: 56, radius: AppRadius.sm),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBSkeleton(height: 16), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 12, width: 220)])),
          ]),
        ),
      ),
    ),
  );
}

class MiniCalendar extends StatelessWidget {
  const MiniCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month);
    final days = DateUtils.getDaysInMonth(today.year, today.month);
    final leading = first.weekday - 1;
    final locale = context.locale.toLanguageTag();
    final monday = DateTime(2024, 1, 1);
    return Column(children: [
      Text(DateFormat.yMMMM(locale).format(today), style: context.textStyles.titleMedium),
      const SizedBox(height: AppSpacing.md),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 7, childAspectRatio: 1, children: [
        for (var index = 0; index < 7; index++) Center(child: Text(DateFormat.E(locale).format(monday.add(Duration(days: index))).substring(0, 1).toUpperCase(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))),
        for (var index = 0; index < leading; index++) const SizedBox.shrink(),
        for (var day = 1; day <= days; day++) Center(child: Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: day == today.day ? LightModeColors.lightPrimary : Colors.transparent), child: Text('$day', style: context.textStyles.bodySmall?.copyWith(color: day == today.day ? Colors.white : LightModeColors.lightOnSurface)))),
      ]),
    ]);
  }
}