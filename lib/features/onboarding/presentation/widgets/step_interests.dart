import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/onboarding/domain/hunting_interest.dart';

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
      children: huntingInterests.map((interest) {
        final isSelected = selected.contains(interest.id);
        return ChoiceChip(
          label: Text(interest.translationKey.tr()),
          avatar: Icon(interest.icon, size: 18, color: isSelected ? Colors.white : LightModeColors.lightOnSurfaceVariant),
          selected: isSelected,
          onSelected: (_) => onToggle(interest.id),
          showCheckmark: false,
          labelStyle: context.textStyles.labelLarge?.withColor(isSelected ? Colors.white : LightModeColors.lightOnSurface),
          selectedColor: LightModeColors.lightPrimary,
          backgroundColor: LightModeColors.lightSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        );
      }).toList(),
    );
  }
}
