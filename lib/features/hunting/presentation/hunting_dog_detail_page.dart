import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/domain/hunting_dog.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';

class HuntingDogDetailPage extends ConsumerWidget {
  final String dogId;
  final bool debugPreview;
  const HuntingDogDetailPage({super.key, required this.dogId, this.debugPreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugPreview) return const HuntingDogDetailBody(dog: null);
    return ref.watch(dogByIdProvider(dogId)).when(
      loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBSkeleton(height: 420, radius: AppRadius.lg))),
      error: (error, stack) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'dogs.error_title'.tr(), message: 'dogs.error_message'.tr()))),
      data: (dog) => dog == null ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.not_found'.tr(), message: 'dogs.not_found_message'.tr()))) : HuntingDogDetailBody(dog: dog),
    );
  }
}

class HuntingDogDetailBody extends StatefulWidget {
  final HuntingDog? dog;
  const HuntingDogDetailBody({super.key, required this.dog});

  @override
  State<HuntingDogDetailBody> createState() => _HuntingDogDetailBodyState();
}

class _HuntingDogDetailBodyState extends State<HuntingDogDetailBody> {
  int _tab = 0;

  void _soon(BuildContext context) => showComingSoonInfo(context, icon: Icons.pets_outlined, title: 'common.coming_soon_title'.tr(), message: 'dogs.p29_message'.tr());

  @override
  Widget build(BuildContext context) {
    final dog = widget.dog;
    final age = dog?.birthDate == null ? '—' : 'dogs.age_years'.tr(namedArgs: {'count': '${DateTime.now().year - dog!.birthDate!.year}'});
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(height: 160, decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.lg)), child: const Center(child: Icon(Icons.pets_outlined, size: 48, color: LightModeColors.lightTextTertiary))),
        Positioned(left: AppSpacing.lg, bottom: -48, child: HBAvatar(name: dog?.name, size: 96, ringColor: LightModeColors.lightSurface)),
      ]),
      const SizedBox(height: 60),
      Text(dog?.name ?? '—', style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.xs),
      Text('${dog?.breed ?? '—'} · ${dog?.sex ?? '—'} · $age', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBChip(label: '${'dogs.pedigree'.tr()} ${dog?.pedigreeNumber ?? '—'}', selected: false), HBChip(label: '${'dogs.microchip'.tr()} ${dog?.microchipNumber ?? '—'}', selected: false), HBChip(label: '${'dogs.owner'.tr()} ${dog?.ownerName ?? '—'}', selected: false)]),
      const SizedBox(height: AppSpacing.md),
      Row(children: [HBButton.secondary(label: 'dogs.edit'.tr(), onPressed: () => _soon(context)), const SizedBox(width: AppSpacing.sm), HBButton.ghost(label: 'dogs.share'.tr(), onPressed: () => _soon(context))]),
      const SizedBox(height: AppSpacing.lg),
      HBSegmentedTabs(labels: ['dogs.tab_profile'.tr(), 'dogs.tab_outings'.tr(), 'dogs.tab_trials'.tr(), 'dogs.tab_health'.tr()], selectedIndex: _tab, onChanged: (index) => setState(() => _tab = index)),
      const SizedBox(height: AppSpacing.lg),
      HBCard(child: HBEmptyState(icon: _tab == 3 ? Icons.health_and_safety_outlined : Icons.pets_outlined, title: _emptyTitle(), message: _emptyMessage())),
      const SizedBox(height: AppSpacing.xl),
    ]))]));
  }

  String _emptyTitle() => ['dogs.profile_empty', 'dogs.outings_empty', 'dogs.trials_empty', 'dogs.health_empty'][_tab].tr();
  String _emptyMessage() => (_tab == 3 ? 'dogs.health_empty_message' : 'dogs.tab_empty_message').tr();
}