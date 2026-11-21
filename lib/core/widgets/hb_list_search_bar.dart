import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// PD4b list search row: a 52 px white pill with a 20 px lens and a 15/400
/// placeholder, plus an optional 52 px square filter button on the right.
class HBListSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilters;
  final int activeFilters;

  const HBListSearchBar({super.key, required this.controller, required this.hint, this.onChanged, this.onFilters, this.activeFilters = 0});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: LightModeColors.border)),
      child: Row(children: [
        const Icon(Icons.search_rounded, size: 20, color: LightModeColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppText.body.withColor(LightModeColors.text),
          decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: hint, hintStyle: AppText.body.withColor(LightModeColors.textSecondary)),
        )),
      ]),
    )),
    if (onFilters != null) ...[
      const SizedBox(width: AppSpacing.sm),
      InkWell(
        borderRadius: BorderRadius.circular(AppRadius.inner),
        onTap: onFilters,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.inner), border: Border.all(color: LightModeColors.border)),
          child: Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.tune_rounded, size: 20, color: LightModeColors.text),
            if (activeFilters > 0) Positioned(right: -6, top: -4, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: LightModeColors.bosco, shape: BoxShape.circle))),
          ]),
        ),
      ),
    ],
  ]);
}

/// PD4b floating pill action (mobile only) that hides while scrolling down and
/// comes back when scrolling up.
class HBScrollHidingAction extends StatelessWidget {
  final bool visible;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const HBScrollHidingAction({super.key, required this.visible, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => AnimatedSlide(
    offset: visible ? Offset.zero : const Offset(0, 1.6),
    duration: const Duration(milliseconds: 200),
    curve: AppMotion.enter,
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: LightModeColors.bosco,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPressed,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), boxShadow: AppShadows.fab),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppText.buttonLg.withColor(Colors.white)),
            ]),
          ),
        ),
      ),
    ),
  );
}
