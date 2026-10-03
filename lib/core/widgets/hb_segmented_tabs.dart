import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Soft segmented control: a neutral pill container with an animated white
/// "active" pill (level1 shadow, primaryDeep text) that slides between
/// options. Used for feed filters (Per te / Seguiti / Vicino) and similar
/// 2-4 option toggles.
class HBSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const HBSegmentedTabs({super.key, required this.labels, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  boxShadow: isActive ? AppShadows.level1 : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: context.textStyles.labelLarge?.withColor(isActive ? LightModeColors.lightForest : LightModeColors.lightOnSurfaceVariant),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
