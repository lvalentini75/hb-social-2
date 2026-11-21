import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';

/// PD4b single-select filter chips shared by every list page.
///
/// Up to [wrapThreshold] chips they wrap on multiple lines (gap 8/10); beyond
/// that they stay on one horizontally scrollable line.
class HBFilterChipsRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int wrapThreshold;

  const HBFilterChipsRow({super.key, required this.labels, required this.selectedIndex, required this.onChanged, this.wrapThreshold = 8});

  @override
  Widget build(BuildContext context) {
    final chips = [for (var index = 0; index < labels.length; index++) HBChip(label: labels[index], selected: index == selectedIndex, onTap: () => onChanged(index))];
    if (labels.length <= wrapThreshold) {
      return Align(alignment: Alignment.centerLeft, child: Wrap(spacing: AppSpacing.sm, runSpacing: 10, children: chips));
    }
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent], stops: [0, .025, .975, 1]).createShader(bounds),
      child: SizedBox(height: 40, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => chips[index],
      )),
    );
  }
}
