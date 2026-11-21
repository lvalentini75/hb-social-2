import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';

/// Reusable dog collection used by the owner page and public profiles.
class DogCards extends StatelessWidget {
  final List<Dog> dogs;
  final bool compact;
  const DogCards({super.key, required this.dogs, this.compact = false});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = !compact && constraints.maxWidth >= 760 ? 3 : 1;
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, mainAxisExtent: columns == 1 ? 132 : 238), itemCount: dogs.length, itemBuilder: (_, index) => DogProfileCard(dog: dogs[index], horizontal: columns == 1));
  });
}

/// Summary card for a visible dog.
class DogProfileCard extends StatelessWidget {
  final Dog dog;
  final bool horizontal;
  const DogProfileCard({super.key, required this.dog, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final avatar = HBAvatar(name: dog.name, imageUrl: dog.avatarUrl, size: horizontal ? 76 : 88);
    final details = Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
      Row(mainAxisSize: horizontal ? MainAxisSize.max : MainAxisSize.min, children: [Flexible(child: Text(dog.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium)), if (dog.status != DogStatus.active) ...[const SizedBox(width: AppSpacing.xs), HBStatusChip(kind: dog.status == DogStatus.deceased ? HBStatusKind.neutral : HBStatusKind.info, label: dog.status.labelKey.tr())]]),
      const SizedBox(height: AppSpacing.xs),
      Text([dog.breed ?? 'dogs.mixed_breed'.tr(), if (dog.sex != null) 'dogs.sex.${dog.sex}'.tr(), dogAgeLabel(context, dog.ageMonths)].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: horizontal ? TextAlign.start : TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.sm),
      Text('dogs.card_stats'.tr(namedArgs: {'outings': '${dog.outingCount}', 'harvests': '${dog.harvestTotal}', 'trials': '${dog.trialCount}'}), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall),
      if (dog.visibility != DogVisibility.public) ...[const SizedBox(height: AppSpacing.xs), Row(mainAxisSize: MainAxisSize.min, children: [Icon(dog.visibility == DogVisibility.private ? Icons.lock_outline_rounded : Icons.people_outline_rounded, size: 16, color: LightModeColors.lightTextTertiary), const SizedBox(width: 4), Text(dog.visibility.labelKey.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))])],
    ]);
    return GestureDetector(onTap: () => context.push(AppRoutes.dogDetailPath(dog.id)), child: HBCard(child: horizontal ? Row(children: [avatar, const SizedBox(width: AppSpacing.md), Expanded(child: details)]) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [avatar, const SizedBox(height: AppSpacing.md), details])));
  }
}

String dogAgeLabel(BuildContext context, int? months) {
  if (months == null) return 'dogs.age_unknown'.tr();
  if (months < 12) return 'dogs.puppy'.tr();
  final years = months ~/ 12;
  final remaining = months % 12;
  return remaining == 0 ? 'dogs.age_years_only'.tr(namedArgs: {'years': '$years'}) : 'dogs.age_years_months'.tr(namedArgs: {'years': '$years', 'months': '$remaining'});
}