import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/core/theme/app_theme.dart';

class HbBarChartPoint {
  final DateTime day;
  final int value;
  final String? label;
  const HbBarChartPoint({required this.day, required this.value, this.label});
}

/// Lightweight daily bar chart with touch/hover tooltips and integer labels.
class HbBarChart extends StatelessWidget {
  final List<HbBarChartPoint> points;
  final double height;
  final bool horizontal;
  const HbBarChart({super.key, required this.points, this.height = 220, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(0, (value, point) => math.max(value, point.value));
    if (maxValue == 0) return SizedBox(height: height, child: Center(child: Text('studio_overview.no_period_data'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))));
    if (horizontal) return SizedBox(height: math.max(height, points.length * 42), child: Column(children: [for (final point in points) Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [SizedBox(width: 112, child: Text(point.label ?? DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(point.day), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall)), const SizedBox(width: AppSpacing.sm), Expanded(child: FractionallySizedBox(widthFactor: math.max(0.02, point.value / maxValue), alignment: Alignment.centerLeft, child: Container(decoration: BoxDecoration(color: LightModeColors.lightPrimary, borderRadius: BorderRadius.circular(AppRadius.pill))))), const SizedBox(width: AppSpacing.sm), SizedBox(width: 32, child: Text('${point.value}', textAlign: TextAlign.end, style: context.textStyles.labelMedium))])))]));
    final middle = (maxValue / 2).round();
    final ticks = <int>[maxValue, if (middle > 0 && middle < maxValue) middle, 0];
    final labelEvery = points.length >= 60 ? 15 : 7;
    return SizedBox(height: height, child: Row(children: [
      SizedBox(width: 32, child: Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [for (final tick in ticks) Text('$tick', style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))]))),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var index = 0; index < points.length; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                     Expanded(child: Align(alignment: Alignment.bottomCenter, child: Tooltip(message: '${points[index].label ?? DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(points[index].day)} · ${points[index].value}', triggerMode: TooltipTriggerMode.tap, child: FractionallySizedBox(heightFactor: math.max(0.02, points[index].value / maxValue), widthFactor: 1, alignment: Alignment.bottomCenter, child: Container(decoration: const BoxDecoration(color: LightModeColors.lightPrimary, borderRadius: BorderRadius.vertical(top: Radius.circular(3)))))))),
                    const SizedBox(height: AppSpacing.xs),
                     SizedBox(height: 20, child: index % labelEvery == 0 ? FittedBox(fit: BoxFit.scaleDown, child: Text(points[index].label ?? DateFormat.Md(Localizations.localeOf(context).toLanguageTag()).format(points[index].day), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))) : null),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    ]));
  }
}