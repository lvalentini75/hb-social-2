import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';
import 'package:hb_social/features/admin/providers/admin_p44_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminHuntingOverviewPage extends ConsumerWidget {
  const AdminHuntingOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminCalendarStatsProvider(null));
    return CustomScrollView(slivers: [SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.hunting.overview.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('admin.hunting.overview.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.lg), state.when(loading: () => const HBSkeleton(height: 420), error: (_, __) => HBEmptyState(icon: Icons.cloud_off_outlined, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr()), data: (value) => AdminHuntingOverviewContent(value: value))]))]);
  }
}

class AdminHuntingOverviewContent extends StatelessWidget {
  final AdminCalendarsStats value;
  const AdminHuntingOverviewContent({super.key, required this.value});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [for (final country in value.countries) SizedBox(width: 310, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${country.countryCode} · ${country.seasonLabel}', style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), Text('admin.hunting.overview.coverage'.tr(namedArgs: {'covered': '${country.regionsCovered}', 'total': '${country.regionsTotal}'})), const SizedBox(height: AppSpacing.sm), Text('admin.hunting.overview.country_counts'.tr(namedArgs: {'published': '${country.published}', 'drafts': '${country.drafts}', 'species': '${country.species}', 'units': '${country.unitsWithArea}', 'layers': '${country.layersPublished}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])))]),
    const SizedBox(height: AppSpacing.lg),
    Text('admin.hunting.overview.regions'.tr(), style: context.textStyles.titleLarge),
    const SizedBox(height: AppSpacing.sm),
    AdminDataTable(headers: [for (final key in const ['region','published','drafts','current','next','updated','actions']) 'admin.hunting.overview.columns.$key'.tr()], columnWidths: const [220,90,90,130,130,160,120], emptyMessage: 'admin.hunting.overview.regions_empty'.tr(), rows: [for (final region in value.regions) [Text(region.name), Text('${region.published}'), Text('${region.drafts}'), Text(region.currentSeason ?? '-'), Text('${region.nextSeasonDrafts}'), Text(region.lastUpdate == null ? '-' : timeago.format(region.lastUpdate!.toLocal(), locale: context.locale.languageCode)), TextButton(onPressed: () => context.go('/admin/hunting/calendars?region=${region.regionId}'), child: Text('common.open'.tr()))]]),
    const SizedBox(height: AppSpacing.lg),
    Text('admin.hunting.overview.expiring'.tr(), style: context.textStyles.titleLarge),
    const SizedBox(height: AppSpacing.sm),
    HBCard(child: value.expiring.isEmpty ? HBEmptyState(icon: Icons.event_available_outlined, title: 'admin.hunting.overview.no_expiring'.tr(), message: 'admin.hunting.overview.no_expiring_help'.tr()) : Column(children: [for (final item in value.expiring) ListTile(contentPadding: EdgeInsets.zero, title: Text(item.speciesName), subtitle: Text('${item.regionName} · ${DateFormat.yMd(context.locale.languageCode).format(item.validTo)}'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/admin/hunting/calendars/${item.calendarId}'))])),
    const SizedBox(height: AppSpacing.md),
    Text('admin.hunting.overview.version'.tr(namedArgs: {'version': value.version}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary)),
  ]);
}