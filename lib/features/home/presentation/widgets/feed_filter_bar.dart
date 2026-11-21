import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// PD4 feed filter bar: a white card holding 40 px pill chips and the
/// trailing square filter button.
class FeedFilterBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onRefresh;

  const FeedFilterBar({super.key, required this.labels, required this.selectedIndex, required this.onChanged, this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.cardWeb), boxShadow: AppShadows.card),
    child: Row(children: [
      Expanded(child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var index = 0; index < labels.length; index++) Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FeedFilterChip(label: labels[index], selected: index == selectedIndex, onTap: () => onChanged(index)),
          ),
        ]),
      )),
      if (onRefresh != null) ...[
        const SizedBox(width: AppSpacing.sm),
        Material(
          color: LightModeColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.nav),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.nav),
            onTap: onRefresh,
            child: const SizedBox(width: 40, height: 40, child: Icon(Icons.tune_rounded, size: 20, color: LightModeColors.text)),
          ),
        ),
      ],
    ]),
  );
}

class FeedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FeedFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? LightModeColors.bosco : LightModeColors.surface,
    shape: StadiumBorder(side: selected ? BorderSide.none : const BorderSide(color: LightModeColors.border)),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(label, style: selected ? AppText.buttonSm.withColor(Colors.white) : AppText.label.withColor(LightModeColors.text)),
      ),
    ),
  );
}

/// Translated labels of the shared feed filters, plus the UI-only "most
/// recent" chip (reuses the for-you feed, which is already date-sorted).
List<String> feedFilterLabels() => ['home.filter_for_you'.tr(), 'home.filter_following'.tr(), 'home.filter_nearby'.tr(), 'home.filter_most_recent'.tr()];
