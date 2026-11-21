import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';

class AdminPlatformConfigPage extends ConsumerStatefulWidget {
  const AdminPlatformConfigPage({super.key});
  @override ConsumerState<AdminPlatformConfigPage> createState() => _AdminPlatformConfigPageState();
}

class _AdminPlatformConfigPageState extends ConsumerState<AdminPlatformConfigPage> {
  int tab = 0;
  AdminCountryPolicyOverview? selected;
  final search = TextEditingController();
  @override void dispose() { search.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final configuration = ref.watch(adminPlatformConfigurationProvider);
    final countries = ref.watch(adminCountryPoliciesProvider);
    return Stack(children: [
      AdminListPage(title: 'admin.p05c.configTitle'.tr(), description: 'admin.p05c.configDescription'.tr(), filters: Row(children: [SizedBox(width: 600, child: HBSegmentedTabs(labels: ['admin.p05c.configTabs.countries'.tr(), 'admin.p05c.configTabs.flags'.tr(), 'admin.p05c.configTabs.rates'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value))), if (tab == 0) ...[const SizedBox(width: AppSpacing.md), SizedBox(width: 280, child: HBInput(controller: search, hint: 'country.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (_) => setState(() {})))]]), emptyMessage: 'admin.p05c.configEmpty'.tr(), onRetry: configuration.hasError || countries.hasError ? () { ref.invalidate(adminPlatformConfigurationProvider); ref.invalidate(adminCountryPoliciesProvider); } : null, content: switch (tab) { 0 => countries.when(loading: () => const AdminDataTable(headers: ['','','','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => const SizedBox.shrink(), data: (items) { final query = search.text.trim().toLowerCase(); final filtered = items.where((item) => query.isEmpty || item.countryName.toLowerCase().contains(query) || item.countryCode.toLowerCase().contains(query)).toList()..sort((a, b) { final policy = (b.hasExplicitPolicy ? 1 : 0).compareTo(a.hasExplicitPolicy ? 1 : 0); return policy != 0 ? policy : a.countryName.compareTo(b.countryName); }); return AdminCountriesTable(items: filtered, onSelected: (country) => setState(() => selected = country)); }), 1 => configuration.when(loading: () => const AdminDataTable(headers: ['','','','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => const SizedBox.shrink(), data: (data) => AdminFlagsTable(flags: data.flags)), _ => configuration.when(loading: () => const AdminDataTable(headers: ['','','','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => const SizedBox.shrink(), data: (data) => AdminRatesTable(rates: data.exchangeRates)) }),
      if (selected != null) AdminDetailOverlay(onClose: () => setState(() => selected = null), panel: AdminCountryDetailPanel(country: selected!, onClose: () => setState(() => selected = null))),
    ]);
  }
}

class AdminCountriesTable extends StatelessWidget {
  final List<AdminCountryPolicyOverview> items;
  final ValueChanged<AdminCountryPolicyOverview> onSelected;
  const AdminCountriesTable({super.key, required this.items, required this.onSelected});
  @override Widget build(BuildContext context) => AdminDataTable(headers: [for (final key in ['country','firearms','badge','age','sensitive','listings','shops','updated']) 'admin.countries.columns.$key'.tr()], columnWidths: const [180,150,120,80,130,100,100,130], emptyMessage: 'admin.p05c.countriesEmpty'.tr(), rows: [for (final country in items) [Text('${countryFlag(country.countryCode)}  ${country.countryName}'), HBStatusChip(kind: country.firearmsMode == 'mediated_showcase' ? HBStatusKind.approved : HBStatusKind.pending, label: 'admin.countries.mode.${country.firearmsMode}'.tr()), Text('verification.badge.${country.requiresBadge}'.tr()), Text('${country.minimumAge}'), Text((country.blurHarvestPhotos ? 'admin.countries.yes' : 'admin.countries.no').tr()), Text('${country.firearmsListings}'), Text('${country.gunShopsVerified}'), Text(country.updatedAt == null ? 'common.unavailable'.tr() : relativeTime(context, country.updatedAt!))]], rowCallbacks: [for (final country in items) () => onSelected(country)]);
}

class AdminFlagsTable extends StatelessWidget {
  final List<AdminFeatureFlag> flags;
  const AdminFlagsTable({super.key, required this.flags});
  @override Widget build(BuildContext context) => AdminDataTable(headers: [for (final key in ['module','country','status','rollout','description','updated']) 'admin.p05c.flagColumns.$key'.tr()], columnWidths: const [190,100,100,100,300,150], emptyMessage: 'admin.p05c.flagsEmpty'.tr(), rows: [for (final flag in flags) [Text(flag.module), Text(flag.countryCode ?? 'admin.p05c.allCountries'.tr()), HBStatusChip(kind: flag.isEnabled ? HBStatusKind.approved : HBStatusKind.neutral, label: (flag.isEnabled ? 'admin.p05c.enabled' : 'admin.p05c.disabled').tr()), Text('${flag.rolloutPercentage}%'), Text(flag.description ?? 'common.unavailable'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis), Text(relativeTime(context, flag.updatedAt))]]);
}

class AdminRatesTable extends StatelessWidget {
  final List<AdminExchangeRate> rates;
  const AdminRatesTable({super.key, required this.rates});
  @override Widget build(BuildContext context) => AdminDataTable(headers: [for (final key in ['pair','rate','validOn','source']) 'admin.p05c.rateColumns.$key'.tr()], columnWidths: const [180,180,160,260], emptyMessage: 'admin.p05c.ratesEmpty'.tr(), rows: [for (final rate in rates) [Text('${rate.baseCode} → ${rate.quoteCode}'), Text(rate.rate), Text(DateFormat.yMd(context.locale.toString()).format(rate.validOn)), Wrap(spacing: AppSpacing.xs, children: [Text(rate.source ?? 'common.unavailable'.tr()), if ((rate.source ?? '').toUpperCase().contains('DATI DI PROVA')) HBStatusChip(kind: HBStatusKind.pending, label: 'admin.p05c.testData'.tr())])]]);
}

class AdminCountryDetailPanel extends ConsumerWidget {
  final AdminCountryPolicyOverview country;
  final VoidCallback onClose;
  const AdminCountryDetailPanel({super.key, required this.country, required this.onClose});
  @override Widget build(BuildContext context, WidgetRef ref) { final role = ref.watch(adminAccessProvider).value?.roleName; final canEdit = role == 'superadmin' || role == 'admin'; return AdminDetailPanel(title: '${countryFlag(country.countryCode)} ${country.countryName}', onClose: onClose, actions: const [], body: Column(children: [if (!canEdit) HBCard(color: LightModeColors.lightBackgroundSoft, child: Text('admin.countries.read_only'.tr())), CountryPolicyEditor(country: country, editable: canEdit)])); }
}

class CountryPolicyEditor extends ConsumerStatefulWidget {
  final AdminCountryPolicyOverview country;
  final bool editable;
  const CountryPolicyEditor({super.key, required this.country, required this.editable});
  @override ConsumerState<CountryPolicyEditor> createState() => _CountryPolicyEditorState();
}

class _CountryPolicyEditorState extends ConsumerState<CountryPolicyEditor> {
  late String mode = widget.country.firearmsMode;
  late String badge = widget.country.requiresBadge;
  late Set<String> types = widget.country.allowedTypes.toSet();
  late int age = widget.country.minimumAge;
  late bool blur = widget.country.blurHarvestPhotos;
  late bool allow = widget.country.allowHarvestPhotos;
  final notes = TextEditingController();
  bool saving = false;
  @override void dispose() { notes.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Column(children: [AdminDetailCard(title: 'admin.countries.firearms'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBFormField(label: 'admin.countries.mode_label'.tr(), child: IgnorePointer(ignoring: !widget.editable, child: HBChoice<String>(options: const ['disabled', 'mediated_showcase'], value: mode, onChanged: (value) => setState(() => mode = value), labelBuilder: (value) => 'admin.countries.mode.$value'.tr()))), const SizedBox(height: AppSpacing.md), HBFormField(label: 'admin.countries.badge_label'.tr(), child: IgnorePointer(ignoring: !widget.editable, child: HBChoice<String>(options: const ['hunter', 'gun_shop'], value: badge, onChanged: (value) => setState(() => badge = value), labelBuilder: (value) => 'verification.badge.$value'.tr()))), const SizedBox(height: AppSpacing.md), Text('admin.countries.types'.tr(), style: context.textStyles.labelLarge), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final type in const ['shotgun','rifle','combination','air_rifle','ammunition','reloading']) HBChip(label: 'marketplace.firearms.type.$type'.tr(), selected: types.contains(type), onTap: widget.editable ? () => setState(() => types.contains(type) ? types.remove(type) : types.add(type)) : null)]), const SizedBox(height: AppSpacing.md), HBFormField(label: 'admin.countries.notes'.tr(), child: HBInput(controller: notes, enabled: widget.editable, maxLines: 3)), const SizedBox(height: AppSpacing.md), Text('admin.countries.notice_preview'.tr(), style: context.textStyles.labelLarge), Text(widget.country.noticeKey.tr()), const SizedBox(height: AppSpacing.sm), AdminLabelValueRow(label: 'admin.countries.in_app_payment'.tr(), value: 'admin.countries.no'.tr()), if (widget.editable) Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: saving ? null : saveFirearms)) ])), AdminDetailCard(title: 'admin.countries.minimum_age'.tr(), child: IgnorePointer(ignoring: !widget.editable, child: HBChoice<int>(options: const [18,19,20,21], value: age, onChanged: (value) => setState(() => age = value), labelBuilder: (value) => '$value'))), AdminDetailCard(title: 'admin.countries.sensitive'.tr(), child: Column(children: [SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('admin.countries.blur'.tr()), value: blur, onChanged: widget.editable ? (value) => setState(() => blur = value) : null), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('admin.countries.allow'.tr()), value: allow, onChanged: widget.editable ? (value) => setState(() => allow = value) : null), if (widget.editable) Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: saving ? null : saveGeneral))]))]);
  Future<bool> confirm() async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('admin.countries.confirm_title'.tr()), content: Text('admin.countries.confirm_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'common.confirm'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
  Future<void> saveFirearms() async { if (!await confirm()) return; await run(() => ref.read(adminListRepositoryProvider).upsertCountryPolicy(countryCode: widget.country.countryCode, policyType: 'firearms_marketplace', data: {'mode': mode, 'requires_badge': badge, 'contact_via': 'gun_shop', 'in_app_payment': false, 'allowed_types': types.toList(), 'notice_key': widget.country.noticeKey, 'internal_notes': notes.text.trim()})); }
  Future<void> saveGeneral() async { if (!await confirm()) return; await run(() async { final repository = ref.read(adminListRepositoryProvider); await repository.upsertCountryPolicy(countryCode: widget.country.countryCode, policyType: 'minimum_age', data: {'minimum_age': age}); await repository.upsertCountryPolicy(countryCode: widget.country.countryCode, policyType: 'sensitive_content', data: {'blur_harvest_photos': blur, 'allow_harvest_photos': allow}); }); }
  Future<void> run(Future<void> Function() action) async { setState(() => saving = true); try { await action(); ref.invalidate(adminCountryPoliciesProvider); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.countries.saved'.tr()))); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class PolicyDetail extends StatelessWidget {
  final AdminCountryPolicy policy;
  const PolicyDetail({super.key, required this.policy});
  @override Widget build(BuildContext context) {
    final values = policy.policyData.entries.expand((entry) => flattenPolicy(entry.key, entry.value)).toList();
    return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(policy.policyType, style: context.textStyles.bodyMedium?.bold), for (final entry in values) AdminLabelValueRow(label: readablePolicyKey(entry.key), value: readablePolicyValue(entry.value)), Wrap(spacing: AppSpacing.xs, children: [if (values.any((entry) => entry.value == 'disabled')) HBStatusChip(kind: HBStatusKind.pending, label: 'admin.p05c.disabled'.tr()), if (values.any((entry) => entry.value == 'mediated_showcase')) HBStatusChip(kind: HBStatusKind.approved, label: 'admin.p05c.mediatedShowcase'.tr())]) ]));
  }
}

class AdminPluginsPage extends StatelessWidget {
  const AdminPluginsPage({super.key});
  @override Widget build(BuildContext context) => AdminListPage(title: 'admin.modules.plugins.title'.tr(), description: 'admin.modules.plugins.description'.tr(), filters: Text('admin.p05c.readOnly'.tr()), emptyMessage: 'admin.p05c.pluginsP42'.tr(), content: HBEmptyState(icon: Icons.extension_outlined, title: 'admin.modules.plugins.title'.tr(), message: 'admin.p05c.pluginsP42'.tr()));
}

String countryFlag(String code) => String.fromCharCodes(code.toUpperCase().codeUnits.map((unit) => 0x1F1E6 + unit - 65));
Iterable<MapEntry<String, dynamic>> flattenPolicy(String key, dynamic value) sync* {
  if (value is Map) {
    for (final entry in value.entries) yield* flattenPolicy('$key.${entry.key}', entry.value);
  } else { yield MapEntry(key, value); }
}
String readablePolicyKey(String value) => value.replaceAll('_', ' ').replaceAll('.', ' / ');
String readablePolicyValue(dynamic value) => value is bool ? (value ? 'admin.p05c.yes' : 'admin.p05c.no').tr() : value.toString().replaceAll('_', ' ');