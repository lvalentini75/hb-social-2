import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p43_providers.dart';

class AdminReleasePanel extends ConsumerStatefulWidget {
  const AdminReleasePanel({super.key});
  @override ConsumerState<AdminReleasePanel> createState() => _AdminReleasePanelState();
}

class _AdminReleasePanelState extends ConsumerState<AdminReleasePanel> {
  final min = TextEditingController(), latest = TextEditingController(), forced = TextEditingController(), ios = TextEditingController(), android = TextEditingController(), web = TextEditingController();
  final messages = {for (final locale in const ['it','en','fr','es','de']) locale: TextEditingController()};
  bool updateAvailable = false, maintenance = false, loaded = false, saving = false;
  final firearms = <String>{};
  @override void dispose() { min.dispose(); latest.dispose(); forced.dispose(); ios.dispose(); android.dispose(); web.dispose(); for (final item in messages.values) { item.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    final config = ref.watch(platformConfigProvider);
    config.whenData((value) { if (!loaded) { loaded = true; final release = value.release; min.text = release.minAppVersion; latest.text = release.latestAppVersion; forced.text = release.forceUpdateBelow; ios.text = release.storeUrls['ios'] ?? ''; android.text = release.storeUrls['android'] ?? ''; web.text = release.webUrl; updateAvailable = release.updateAvailable; maintenance = release.maintenanceMode; firearms.addAll(release.firearmsShowcasePlatforms); for (final entry in messages.entries) { entry.value.text = release.maintenanceMessage[entry.key] ?? ''; } } });
    final superadmin = ref.watch(adminAccessProvider).value?.roleName == 'superadmin';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ref.watch(adminHealthProvider).when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('admin.release.health_error'.tr()), data: (value) => HBCard(child: ListTile(leading: Icon(value['ok'] == true ? Icons.check_circle : Icons.error_outline, color: value['ok'] == true ? LightModeColors.success : LightModeColors.lightError), title: Text('admin.release.health'.tr()), subtitle: Text('admin.release.health_value'.tr(namedArgs: {'schema': '${value['schema'] ?? ''}', 'maintenance': '${value['maintenance'] ?? false}'}))))), const SizedBox(height: AppSpacing.md), HBCard(child: IgnorePointer(ignoring: !superadmin, child: Column(children: [HBInput(controller: min, label: 'admin.release.min_version'.tr()), HBInput(controller: latest, label: 'admin.release.latest_version'.tr()), HBInput(controller: forced, label: 'admin.release.force_below'.tr()), HBInput(controller: ios, label: 'admin.release.ios_url'.tr()), HBInput(controller: android, label: 'admin.release.android_url'.tr()), HBInput(controller: web, label: 'admin.release.web_url'.tr()), SwitchListTile(value: updateAvailable, onChanged: (value) => setState(() => updateAvailable = value), title: Text('admin.release.update_available'.tr()), subtitle: Text('admin.release.update_available_help'.tr())), SwitchListTile(value: maintenance, onChanged: (value) => setState(() => maintenance = value), title: Text('admin.release.maintenance'.tr())), for (final entry in messages.entries) HBInput(controller: entry.value, label: 'admin.release.message'.tr(namedArgs: {'locale': entry.key.toUpperCase()}), maxLines: 2), Align(alignment: Alignment.centerLeft, child: Wrap(spacing: AppSpacing.sm, children: [for (final platform in const ['web','ios','android']) HBChip(label: 'admin.release.firearms_platform'.tr(namedArgs: {'platform': platform}), selected: firearms.contains(platform), onTap: () => setState(() => firearms.contains(platform) ? firearms.remove(platform) : firearms.add(platform)))])), const SizedBox(height: AppSpacing.md), if (superadmin) Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: _save))])))]);
  }
  Future<void> _save() async { setState(() => saving = true); try { await ref.read(adminP43RepositoryProvider).saveSetting('release', {'min_app_version': min.text.trim(), 'latest_app_version': latest.text.trim(), 'force_update_below': forced.text.trim(), 'update_available': updateAvailable, 'maintenance_mode': maintenance, 'maintenance_message': {for (final entry in messages.entries) entry.key: entry.value.text.trim()}, 'store_urls': {'ios': ios.text.trim(), 'android': android.text.trim()}, 'web_url': web.text.trim(), 'firearms_showcase_platforms': firearms.toList()}); ref.invalidate(platformConfigProvider); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.system.saved'.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class AdminLegalPanel extends ConsumerWidget {
  const AdminLegalPanel({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ref.watch(adminLegalListProvider).when(loading: () => const AdminDataTable(headers: ['','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => HBEmptyState(icon: Icons.gavel_rounded, title: 'admin.legal.error'.tr(), message: 'errors.network'.tr()), data: (items) => AdminDataTable(headers: ['admin.legal.document'.tr(),'admin.legal.version'.tr(),'admin.legal.status'.tr(),'admin.legal.languages'.tr(),'admin.legal.consents'.tr(),'admin.legal.actions'.tr()], emptyMessage: 'admin.legal.empty'.tr(), rows: [for (final item in items) [Text('legal.kind.${item['kind']}'.tr()), Text('${item['version'] ?? ''}'), Text('admin.legal.status_value.${item['status']}'.tr()), Text('${(item['locales'] as List?)?.length ?? 0}/5'), Text('${item['consents'] ?? 0}'), Wrap(spacing: AppSpacing.xs, children: [if (item['status'] == 'draft') HBButton.soft(label: 'admin.legal.edit'.tr(), size: HBButtonSize.sm, onPressed: () => context.push('/admin/system/legal/${item['kind']}/${item['version']}')), if (item['is_current'] == true || item['status'] == 'published') HBButton.secondary(label: 'admin.legal.new_version'.tr(), size: HBButtonSize.sm, onPressed: () => context.push('/admin/system/legal/${item['kind']}/new'))])]])), const SizedBox(height: AppSpacing.lg), const AdminLegalConsentsCard()]);
}

class AdminLegalConsentsCard extends ConsumerStatefulWidget {
  const AdminLegalConsentsCard({super.key});
  @override ConsumerState<AdminLegalConsentsCard> createState() => _AdminLegalConsentsCardState();
}

class _AdminLegalConsentsCardState extends ConsumerState<AdminLegalConsentsCard> {
  String kind = 'privacy';
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.legal.consent_detail'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, children: [for (final item in const ['privacy','terms','community_rules','cookies','ads_policy']) HBChip(label: 'legal.kind.$item'.tr(), selected: kind == item, onTap: () => setState(() => kind = item))]), const SizedBox(height: AppSpacing.md), FutureBuilder<Map<String, dynamic>>(future: ref.read(adminP43RepositoryProvider).legalConsents(kind), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator(); if (snapshot.hasError) return Text('admin.legal.consents_error'.tr()); final value = snapshot.data ?? const {}; final byKind = Map<String, dynamic>.from(value['by_kind'] as Map? ?? const {}); final stats = Map<String, dynamic>.from(byKind[kind] as Map? ?? const {}); final active = (value['active_users'] as num?)?.toInt() ?? 0; final current = (stats['accepted_current'] as num?)?.toInt() ?? 0; final any = (stats['accepted_any'] as num?)?.toInt() ?? 0; final age = (value['age_confirmed'] as num?)?.toInt() ?? 0; final ratio = active == 0 ? 0.0 : current / active; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [LinearProgressIndicator(value: ratio), const SizedBox(height: AppSpacing.xs), Text('admin.legal.accepted_current'.tr(namedArgs: {'accepted':'$current','active':'$active','percent':'${(ratio * 100).round()}'})), Text('admin.legal.accepted_any'.tr(namedArgs: {'count':'$any'})), Text('admin.legal.age_confirmed'.tr(namedArgs: {'count':'$age'}))]); })]));
}

class AdminLaunchChecklistPanel extends ConsumerWidget {
  const AdminLaunchChecklistPanel({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adminLaunchChecklistProvider).when(loading: () => const LinearProgressIndicator(), error: (_, __) => HBEmptyState(icon: Icons.fact_check_outlined, title: 'admin.release.checklist_error'.tr(), message: 'errors.network'.tr()), data: (value) { final items = value['items'] as List? ?? const []; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBCard(color: value['ok'] == true ? LightModeColors.boscoSoft : LightModeColors.surface, child: Text((value['ok'] == true ? 'admin.release.ready' : 'admin.release.not_ready').tr(), style: context.textStyles.titleMedium)), const SizedBox(height: AppSpacing.md), for (final raw in items) Builder(builder: (_) { final item = Map<String, dynamic>.from(raw as Map); return ListTile(minTileHeight: 56, leading: Icon(item['ok'] == true ? Icons.check_circle : Icons.cancel_outlined, color: item['ok'] == true ? LightModeColors.success : LightModeColors.lightError), title: Text('admin.release.check.${item['code']}'.tr()), subtitle: Text(item['detail']?.toString() ?? '')); }), Align(alignment: Alignment.centerRight, child: HBButton.soft(label: 'admin.release.recheck'.tr(), onPressed: () => ref.invalidate(adminLaunchChecklistProvider)))]); });
}