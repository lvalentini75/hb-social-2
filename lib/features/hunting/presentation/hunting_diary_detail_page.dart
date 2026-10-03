import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/presentation/events_page.dart';
import 'package:hb_social/features/hunting/domain/hunting_outing.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';

class HuntingDiaryDetailPage extends ConsumerWidget {
  final String outingId;
  final bool debugPreview;
  const HuntingDiaryDetailPage({super.key, required this.outingId, this.debugPreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugPreview) return const HuntingDiaryDetailBody(outing: null);
    return ref.watch(outingByIdProvider(outingId)).when(
      loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBSkeleton(height: 420, radius: AppRadius.lg))),
      error: (error, stack) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'diary.error_title'.tr(), message: 'diary.error_message'.tr()))),
      data: (outing) => outing == null ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'diary.not_found'.tr(), message: 'diary.not_found_message'.tr()))) : HuntingDiaryDetailBody(outing: outing),
    );
  }
}

class HuntingDiaryDetailBody extends StatelessWidget {
  final HuntingOuting? outing;
  const HuntingDiaryDetailBody({super.key, required this.outing});

  @override
  Widget build(BuildContext context) {
    final started = outing?.startedAt?.toLocal();
    final ended = outing?.endedAt?.toLocal();
    final time = started == null ? '—' : '${DateFormat.jm(context.locale.toLanguageTag()).format(started)}–${ended == null ? '—' : DateFormat.jm(context.locale.toLanguageTag()).format(ended)}';
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [EventDateBlock(date: started, size: 72), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(outing?.zoneName ?? '—', style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: AppSpacing.xs), Text(time, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))]),
      const SizedBox(height: AppSpacing.lg),
      HBCard(child: Row(children: [for (final key in ['diary.weather_temperature', 'diary.weather_wind', 'diary.weather_condition']) Expanded(child: Column(children: [Text('—', style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.xs), Text(key.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))])),
      const SizedBox(height: AppSpacing.lg),
      DiaryDetailSection(title: 'diary.species'.tr(), child: Wrap(spacing: AppSpacing.sm, children: outing?.species.map((item) => HBChip(label: item, selected: false)).toList() ?? const [])),
      DiaryDetailSection(title: 'diary.dogs'.tr(), child: Row(children: [const HBAvatar(isGuest: true, size: 40), const SizedBox(width: AppSpacing.sm), Text('diary.no_dog'.tr())])),
      DiaryDetailSection(title: 'diary.harvests'.tr(), child: Text('diary.no_harvests'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
      DiaryDetailSection(title: 'diary.notes'.tr(), child: Text(outing?.notes ?? '—')),
      DiaryDetailSection(title: 'diary.photos'.tr(), child: Row(children: [for (var i = 0; i < 3; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i < 2 ? AppSpacing.sm : 0), child: AspectRatio(aspectRatio: 1, child: Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: const Icon(Icons.image_outlined, color: LightModeColors.lightTextTertiary)))))])),
      AspectRatio(aspectRatio: 16 / 9, child: Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.lg)), child: const Center(child: Icon(Icons.location_pin, size: 40, color: LightModeColors.lightPrimary)))),
      const SizedBox(height: AppSpacing.xl),
    ]))]));
  }
}

class DiaryDetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const DiaryDetailSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), child]));
}