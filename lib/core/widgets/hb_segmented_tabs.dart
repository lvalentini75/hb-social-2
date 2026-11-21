import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';

enum HBSegmentedTabsVariant { pill, underlined }

/// PD4b segmented control.
///
/// `pill` (list pages): 48 px surfaceSoft rail, radius 999, Bosco active
/// segment with white 15/600 text, inactive 15/500, 180 ms slide.
/// `underlined` (detail pages): 15/600 active label with a 2 px Bosco
/// underline as wide as the label, inactive 15/500 textSecondary, hairline
/// divider below.
class HBSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool scrollable;
  final List<int?>? badges;
  final HBSegmentedTabsVariant variant;

  const HBSegmentedTabs({super.key, required this.labels, required this.selectedIndex, required this.onChanged, this.scrollable = false, this.badges, this.variant = HBSegmentedTabsVariant.pill});

  @override
  Widget build(BuildContext context) => variant == HBSegmentedTabsVariant.pill ? _buildPill(context) : _buildUnderlined(context);

  Widget _badge(int index) => badges != null && index < badges!.length && badges![index] != null
      ? HBBadge.count(count: badges![index]!)
      : const SizedBox.shrink();

  Widget _buildPill(BuildContext context) {
    final tabs = List.generate(labels.length, (index) {
      final isActive = index == selectedIndex;
      final tab = GestureDetector(
        onTap: () => onChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.of(context).base,
          curve: AppMotion.enter,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(color: isActive ? LightModeColors.bosco : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.pill)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(labels[index], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: (isActive ? AppText.buttonLg : AppText.ui).withColor(isActive ? Colors.white : LightModeColors.text))),
            if (badges != null && index < badges!.length && badges![index] != null) ...[const SizedBox(width: AppSpacing.xs), _badge(index)],
          ]),
        ),
      );
      return scrollable ? tab : Expanded(child: tab);
    });
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: scrollable ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tabs)) : Row(children: tabs),
    );
  }

  Widget _buildUnderlined(BuildContext context) {
    final tabs = List.generate(labels.length, (index) {
      final isActive = index == selectedIndex;
      return GestureDetector(
        onTap: () => onChanged(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: (isActive ? AppText.buttonLg : AppText.ui).withColor(isActive ? LightModeColors.text : LightModeColors.textSecondary)),
                if (badges != null && index < badges!.length && badges![index] != null) ...[const SizedBox(width: AppSpacing.xs), _badge(index)],
              ]),
            ),
            AnimatedContainer(duration: AppMotion.of(context).base, height: 2, width: double.infinity, color: isActive ? LightModeColors.bosco : Colors.transparent),
          ]),
        ),
      );
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: tabs))),
      const Divider(height: 1, thickness: 1, color: LightModeColors.divider),
    ]);
  }
}
