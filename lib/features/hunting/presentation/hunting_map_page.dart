import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/page_columns.dart';

class HuntingMapPage extends StatefulWidget {
  const HuntingMapPage({super.key});

  @override
  State<HuntingMapPage> createState() => _HuntingMapPageState();
}

class _HuntingMapPageState extends State<HuntingMapPage> {
  int _selectedLayer = 0;

  @override
  Widget build(BuildContext context) {
    final showRail = MediaQuery.sizeOf(context).width >= AppBreakpoints.railBreakpoint;
    final map = HuntingMapCanvas(selectedLayer: _selectedLayer, onLayerChanged: (index) => setState(() => _selectedLayer = index));
    if (showRail) return PageColumns(center: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), child: map), rail: const HuntingMapPanel());
    return Stack(children: [Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), child: map), const HuntingMapBottomSheet()]);
  }
}

class HuntingMapCanvas extends StatelessWidget {
  final int selectedLayer;
  final ValueChanged<int> onLayerChanged;
  const HuntingMapCanvas({super.key, required this.selectedLayer, required this.onLayerChanged});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: Stack(children: [
      Positioned.fill(child: ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.map_outlined, size: 56, color: LightModeColors.lightTextTertiary), const SizedBox(height: AppSpacing.sm), Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: Text('map.placeholder'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)))]))),
      Positioned(left: AppSpacing.md, right: AppSpacing.md, top: AppSpacing.md, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: HBInput(hint: 'map.search_hint'.tr(), prefixIcon: const Icon(Icons.search_rounded, color: LightModeColors.lightOnSurfaceVariant))),
        const SizedBox(height: AppSpacing.sm),
        HBFilterChipsRow(labels: ['map.layer_units'.tr(), 'map.layer_zones'.tr(), 'map.layer_points'.tr(), 'map.layer_sightings'.tr()], selectedIndex: selectedLayer, onChanged: onLayerChanged),
      ])),
      Positioned(right: AppSpacing.md, bottom: AppSpacing.md, child: Column(children: [HBButton.icon(icon: Icons.my_location_rounded, backgroundColor: LightModeColors.lightSurface, onPressed: () {}), const SizedBox(height: AppSpacing.sm), HBButton.icon(icon: Icons.layers_outlined, backgroundColor: LightModeColors.lightSurface, onPressed: () {})])),
    ]),
  );
}

class HuntingMapPanel extends StatelessWidget {
  const HuntingMapPanel({super.key});

  void _addPoint(BuildContext context) => showComingSoonInfo(context, icon: Icons.add_location_alt_outlined, title: 'common.coming_soon_title'.tr(), message: 'map.p28_message'.tr());

  @override
  Widget build(BuildContext context) => Column(children: [
    PageRailCard(label: 'map.my_points'.tr(), child: HBEmptyState(icon: Icons.bookmark_border_rounded, title: 'map.empty_points'.tr(), message: 'map.empty_points_message'.tr(), action: HBButton.soft(label: 'map.add_point'.tr(), onPressed: () => _addPoint(context)))),
    const SizedBox(height: AppSpacing.md),
    PageRailCard(label: 'map.legend'.tr(), child: const MapLegend()),
  ]);
}

class HuntingMapBottomSheet extends StatelessWidget {
  const HuntingMapBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.16,
    minChildSize: 0.12,
    maxChildSize: 0.7,
    snap: true,
    builder: (context, controller) => Container(
      decoration: const BoxDecoration(color: LightModeColors.lightSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)), boxShadow: AppShadows.level3),
      child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl), children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: LightModeColors.lightDivider, borderRadius: BorderRadius.circular(AppRadius.pill)))),
        const SizedBox(height: AppSpacing.md),
        const HuntingMapPanel(),
      ]),
    ),
  );
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <(Color, String)>[(LightModeColors.lightPrimary, 'map.layer_units'), (LightModeColors.lightInfo, 'map.layer_zones'), (LightModeColors.lightWarning, 'map.layer_points'), (LightModeColors.lightError, 'map.layer_sightings')];
    return Column(children: [for (final entry in entries) Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: entry.$1, shape: BoxShape.circle)), const SizedBox(width: AppSpacing.sm), Text(entry.$2.tr())]))]);
  }
}