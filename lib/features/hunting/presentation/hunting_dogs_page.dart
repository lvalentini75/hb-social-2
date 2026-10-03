import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/domain/hunting_dog.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';

class HuntingDogsPage extends ConsumerWidget {
  const HuntingDogsPage({super.key});

  void _add(BuildContext context) => showComingSoonInfo(context, icon: Icons.pets_outlined, title: 'common.coming_soon_title'.tr(), message: 'dogs.p29_message'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListPageScaffold(
    title: 'dogs.title'.tr(),
    subtitle: 'dogs.subtitle'.tr(),
    action: HBButton.primary(label: 'dogs.add'.tr(), icon: Icons.add_rounded, onPressed: () => _add(context)),
    body: ref.watch(dogsProvider).when(
      loading: () => const DogsGridSkeleton(),
      error: (error, stack) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'dogs.error_title'.tr(), message: 'dogs.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(dogsProvider)))),
      data: (dogs) => dogs.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.empty_title'.tr(), message: 'dogs.empty_message'.tr(), action: HBButton.primary(label: 'dogs.add'.tr(), onPressed: () => _add(context)))) : DogsGrid(dogs: dogs),
    ),
    rail: const DogsRail(),
  );
}

class DogsGrid extends StatelessWidget {
  final List<HuntingDog> dogs;
  const DogsGrid({super.key, required this.dogs});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 700 ? 3 : 2;
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.9), itemCount: dogs.length, itemBuilder: (context, index) => DogCard(dog: dogs[index]));
  });
}

class DogCard extends StatelessWidget {
  final HuntingDog dog;
  const DogCard({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    final age = dog.birthDate == null ? '—' : 'dogs.age_years'.tr(namedArgs: {'count': '${DateTime.now().year - dog.birthDate!.year}'});
    return GestureDetector(onTap: () => context.push(AppRoutes.huntingDogDetailPath(dog.id)), child: HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      HBAvatar(name: dog.name, size: 64),
      const SizedBox(height: AppSpacing.md),
      Text(dog.name ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      Text('${dog.breed ?? '—'} · ${dog.sex ?? '—'} · $age', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.sm),
      Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [if (dog.pedigreeNumber != null) HBChip(label: 'dogs.pedigree'.tr(), selected: false), if (dog.microchipNumber != null) HBChip(label: 'dogs.microchip'.tr(), selected: false)]),
    ])));
  }
}

class DogsGridSkeleton extends StatelessWidget {
  const DogsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 700 ? 3 : 2;
    return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.9, children: List.generate(columns * 2, (_) => const HBCard(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [HBSkeleton(width: 64, height: 64, radius: AppRadius.pill), SizedBox(height: AppSpacing.md), HBSkeleton(width: 100, height: 16), SizedBox(height: AppSpacing.sm), HBSkeleton(width: 140, height: 12)]))));
  });
}

class DogsRail extends StatelessWidget {
  const DogsRail({super.key});

  @override
  Widget build(BuildContext context) => Column(children: [
    PageRailCard(label: 'dogs.rail_cynology'.tr(), child: Column(children: [DogsRailLink(label: 'dogs.breeders'.tr(), path: AppRoutes.pages), DogsRailLink(label: 'dogs.trials'.tr(), path: AppRoutes.events), DogsRailLink(label: 'dogs.breed_groups'.tr(), path: AppRoutes.groups)])),
    const SizedBox(height: AppSpacing.md),
    PageRailCard(label: 'dogs.reminders'.tr(), child: Text('dogs.reminders_empty'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
  ]);
}

class DogsRailLink extends StatelessWidget {
  final String label;
  final String path;
  const DogsRailLink({super.key, required this.label, required this.path});

  @override
  Widget build(BuildContext context) => InkWell(onTap: () => context.go(path), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [Expanded(child: Text(label)), const Icon(Icons.chevron_right_rounded, size: 20, color: LightModeColors.lightOnSurfaceVariant)])));
}