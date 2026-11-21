import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/features/onboarding/domain/interests.dart';

/// Onboarding step 2: selectable chips for hunting disciplines.
class StepInterests extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const StepInterests({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: onboardingInterests
          .map(
            (interest) => HBChip(
              label: interest.translationKey.tr(),
              icon: interest.icon,
              selected: selected.contains(interest.slug),
              onTap: () => onToggle(interest.slug),
            ),
          )
          .toList(),
    );
  }
}
