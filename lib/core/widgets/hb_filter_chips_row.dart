import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';

/// A horizontally scrollable row of single-select [HBChip] filters. Shared
/// by every list page that filters by category (Groups, Forum, Pages,
/// Search) instead of each screen rebuilding its own chip row.
class HBFilterChipsRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const HBFilterChipsRow({super.key, required this.labels, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => HBChip(label: labels[index], selected: index == selectedIndex, onTap: () => onChanged(index)),
      ),
    );
  }
}
