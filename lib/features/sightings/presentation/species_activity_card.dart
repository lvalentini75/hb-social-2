import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class SpeciesActivityCard extends ConsumerStatefulWidget { const SpeciesActivityCard({super.key}); @override ConsumerState<SpeciesActivityCard> createState() => _SpeciesActivityCardState(); }
class _SpeciesActivityCardState extends ConsumerState<SpeciesActivityCard> {
  int days = 30;
  @override Widget build(BuildContext context) { final hunting = ref.watch(huntingContextProvider); final request = (regionId: hunting.regionId, lat: hunting.lat, lng: hunting.lng, days: days); final value = ref.watch(speciesActivityProvider(request)); return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('p30b.activity.title'.tr(), style: context.textStyles.titleLarge)), HBButton.ghost(label: 'p30b.activity.all'.tr(), onPressed: () => context.push('${AppRoutes.sightings}?tab=nearby'))]), HBButton.soft(label: 'sightings.alerts.create'.tr(), icon: Icons.notifications_active_outlined, onPressed: () => context.push('${AppRoutes.sightingAlerts}?create=1')), const SizedBox(height: AppSpacing.sm), HBChoice<int>(options: const [7, 30, 90], value: days, onChanged: (value) => setState(() => days = value), labelBuilder: (value) => 'p30b.days'.tr(namedArgs: {'days': '$value'})), const SizedBox(height: AppSpacing.md), value.when(loading: () => const HBListSkeleton(count: 3), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'sightings.errors.title'.tr(), message: 'sightings.errors.generic'.tr()), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.visibility_outlined, title: 'p30b.activity.empty_title'.tr(), message: 'p30b.activity.empty_message'.tr()) : Column(children: [for (final item in items.take(8)) SpeciesActivityRow(item: item, days: days)]))])); }
}

class SpeciesActivityRow extends StatelessWidget { final SpeciesActivity item; final int days; const SpeciesActivityRow({super.key, required this.item, required this.days}); @override Widget build(BuildContext context) { final trend = item.trendPct; return InkWell(onTap: () => context.push('${AppRoutes.sightings}?tab=nearby&species=${item.speciesId}&days=$days'), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [CircleAvatar(backgroundColor: LightModeColors.lightPrimarySoft, child: Icon(_categoryIcon(item.category), color: LightModeColors.lightPrimary)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.speciesName, style: context.textStyles.titleSmall), Text('p30b.activity.counts'.tr(namedArgs: {'sightings': '${item.sightings}', 'animals': '${item.animals}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), Text('p30b.activity.last'.tr(namedArgs: {'time': timeago.format(item.lastAt.toLocal(), locale: context.locale.languageCode)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBStatusChip(kind: trend == null || trend == 0 ? HBStatusKind.neutral : trend > 0 ? HBStatusKind.approved : HBStatusKind.rejected, label: trend == null ? 'p30b.activity.new'.tr() : '${trend > 0 ? '↑' : trend < 0 ? '↓' : '→'} ${trend.abs().toStringAsFixed(0)}%')]))); } }

IconData _categoryIcon(String category) => switch (category) { 'ungulate' => Icons.pets_outlined, 'waterfowl' => Icons.water_outlined, 'migratory' => Icons.flight_outlined, 'predator' => Icons.visibility_outlined, _ => Icons.eco_outlined };