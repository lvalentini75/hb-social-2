import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/presentation/events_page.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';

class EventDetailPage extends ConsumerWidget {
  final String eventId;
  final bool debugPreview;

  const EventDetailPage({super.key, required this.eventId, this.debugPreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugPreview) return const EventDetailBody(event: null);
    return ref.watch(eventByIdProvider(eventId)).when(
      loading: () => const PageColumns(center: Center(child: CircularProgressIndicator())),
      error: (error, stack) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'events.error_title'.tr(), message: 'events.error_message'.tr()))),
      data: (event) => event == null
          ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.event_busy_outlined, title: 'events.not_found_title'.tr(), message: 'events.not_found_message'.tr())))
          : EventDetailBody(event: event),
    );
  }
}

class EventDetailBody extends ConsumerWidget {
  final HuntingEvent? event;

  const EventDetailBody({super.key, required this.event});

  void _soon(BuildContext context) => showComingSoonInfo(context, icon: Icons.event_outlined, title: 'common.coming_soon_title'.tr(), message: 'events.create_soon'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final date = event?.startsAt?.toLocal();
    final cost = event?.costMinor == null ? '—' : MoneyFormatter.format(amountMinor: event!.costMinor!, currencyCode: event!.currencyCode ?? settings.currencyCode, locale: context.locale);
    final page = PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      AspectRatio(aspectRatio: 16 / 9, child: Stack(children: [Container(color: LightModeColors.lightBackgroundSoft, child: const Center(child: Icon(Icons.image_outlined, size: 44, color: LightModeColors.lightTextTertiary))), Positioned(left: AppSpacing.md, bottom: AppSpacing.md, child: EventDateBlock(date: date))])),
      const SizedBox(height: AppSpacing.lg),
      Text(event?.title ?? '—', style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.md),
      Row(children: [HBAvatar(name: event?.organizerName, size: 32), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(event?.organizerName ?? '—'))]),
      const SizedBox(height: AppSpacing.lg),
      HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(children: [
        EventInfoRow(icon: Icons.schedule_outlined, label: 'events.when'.tr(), value: date == null ? '—' : DateFormat.yMMMMd(context.locale.toLanguageTag()).add_jm().format(date)),
        EventInfoRow(icon: Icons.location_on_outlined, label: 'events.where'.tr(), value: event?.location ?? '—'),
        EventInfoRow(icon: Icons.payments_outlined, label: 'events.cost'.tr(), value: cost),
        EventInfoRow(icon: Icons.people_outline, label: 'events.seats'.tr(), value: event?.capacity?.toString() ?? '—'),
      ])),
      const SizedBox(height: AppSpacing.md),
      Row(children: [Expanded(child: HBButton.primary(label: 'events.join'.tr(), onPressed: () => _soon(context))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.secondary(label: 'events.share'.tr(), onPressed: () => _soon(context)))]),
      const SizedBox(height: AppSpacing.lg),
      AspectRatio(aspectRatio: 16 / 9, child: Container(color: LightModeColors.lightBackgroundSoft, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.location_pin, color: LightModeColors.lightPrimary), const SizedBox(height: AppSpacing.sm), Text('events.map_soon'.tr(), style: context.textStyles.bodySmall)]))),
      const SizedBox(height: AppSpacing.xl),
      Text('events.participants_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [const HBAvatar(isGuest: true, size: 32), const SizedBox(width: AppSpacing.sm), Text('events.participants_empty'.tr())])),
      const SizedBox(height: AppSpacing.xl),
      Text('events.description_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      Text(event?.description ?? '—', style: context.textStyles.bodyMedium),
      const SizedBox(height: AppSpacing.xl),
      Text('events.similar_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBCard(child: HBEmptyState(icon: Icons.event_outlined, title: 'events.similar_empty'.tr(), message: 'events.empty_message'.tr())),
      if (MediaQuery.sizeOf(context).width < 900) const SizedBox(height: 88),
    ]))]));
    if (MediaQuery.sizeOf(context).width >= 900) return page;
    return Stack(children: [page, Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: const BoxDecoration(color: LightModeColors.lightSurface, boxShadow: AppShadows.level3), child: SafeArea(top: false, child: HBButton.primary(label: 'events.join'.tr(), onPressed: () => _soon(context)))))]);
  }
}

class EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const EventInfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Row(children: [Icon(icon, size: 20, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.md), SizedBox(width: 80, child: Text(label, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), Expanded(child: Text(value, textAlign: TextAlign.end, style: context.textStyles.bodyMedium))]));
}