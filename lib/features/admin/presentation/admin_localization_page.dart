import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/admin/domain/admin_p43_models.dart';
import 'package:hb_social/features/admin/presentation/admin_system_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_p43_providers.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:intl/intl.dart';

class AdminLocalizationPage extends ConsumerStatefulWidget {
  const AdminLocalizationPage({super.key});
  @override ConsumerState<AdminLocalizationPage> createState() => _AdminLocalizationPageState();
}
class _AdminLocalizationPageState extends ConsumerState<AdminLocalizationPage> {
  final query = TextEditingController(); String? locale; late Future<List<AdminTranslationOverride>> future = load(); String version = '0'; int tab = 0;
  Future<List<AdminTranslationOverride>> load() { final repository = ref.read(adminP43RepositoryProvider); repository.translationsVersion().then((value) { if (mounted) setState(() => version = value); }); return repository.translations(locale: locale, query: query.text); }
  void refresh() => setState(() => future = load());
  @override void dispose() { query.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AdminListPage(title: 'admin.l10n.title'.tr(), description: 'admin.l10n.subtitle'.tr(), actions: tab == 0 ? [HBButton.primary(label: 'admin.l10n.add'.tr(), icon: Icons.add, onPressed: add)] : [], filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: 8, children: [HBChip(label: 'admin.l10n.overrides'.tr(), selected: tab == 0, onTap: () => setState(() => tab = 0)), HBChip(label: 'admin.translation.title'.tr(), selected: tab == 1, onTap: () => setState(() => tab = 1))]), if (tab == 0) ...[const SizedBox(height: 12), HBInput(controller: query, hint: 'admin.l10n.search'.tr(), onSubmitted: (_) => refresh()), const SizedBox(height: 8), Wrap(spacing: 8, children: [HBChip(label: 'common.all'.tr(), selected: locale == null, onTap: () { locale = null; refresh(); }), for (final item in const ['it','en','fr','es','de']) HBChip(label: item.toUpperCase(), selected: locale == item, onTap: () { locale = item; refresh(); })]), const SizedBox(height: 8), Text('admin.l10n.info'.tr(namedArgs: {'version':version}))]]), emptyMessage: 'admin.l10n.empty'.tr(), content: tab == 1 ? const AdminTranslationConsole() : FutureBuilder<List<AdminTranslationOverride>>(future: future, builder: (context, snapshot) { final items = snapshot.data ?? const []; if (snapshot.hasError) return HBEmptyState(icon: Icons.error_outline, title: 'admin.l10n.error'.tr(), message: 'admin.l10n.error_help'.tr()); return AdminDataTable(headers: ['admin.l10n.key'.tr(),'admin.l10n.language'.tr(),'admin.l10n.value'.tr(),'admin.l10n.author'.tr(),'admin.l10n.updated'.tr(),''], columnWidths: const [240,80,420,160,140,80], emptyMessage: 'admin.l10n.empty'.tr(), isLoading: snapshot.connectionState == ConnectionState.waiting, rows: [for (final item in items) [Text(item.key),Text(item.locale.toUpperCase()),Text(item.value,maxLines:2,overflow:TextOverflow.ellipsis),Text(item.updatedByName ?? ''),Text(relativeTime(context,item.updatedAt)),IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>edit(item))]]); }));
  Future<void> add() async { final source = await rootBundle.loadString('assets/translations/it.json'); final keys = <String>[]; flatten('', jsonDecode(source), keys); if (!mounted) return; await showDialog<void>(context: context, builder: (_) => TranslationOverrideDialog(assetKeys: keys)); refresh(); }
  Future<void> edit(AdminTranslationOverride item) async { await showDialog<void>(context: context, builder: (_) => TranslationOverrideDialog(existing: item)); refresh(); }
  void flatten(String prefix, dynamic value, List<String> result) { if (value is Map) { for (final entry in value.entries) { final key = prefix.isEmpty ? entry.key.toString() : '$prefix.${entry.key}'; flatten(key, entry.value, result); } } else { result.add(prefix); } }
}

class AdminTranslationConsole extends ConsumerWidget {
  const AdminTranslationConsole({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adminTranslationStatsProvider).when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.translation.error'.tr(), message: 'admin.l10n.error_help'.tr()),
    data: (stats) {
      final month = Map<String, dynamic>.from(stats['month'] as Map? ?? const {});
      final chars = (month['chars'] as num?)?.toInt() ?? 0;
      final limit = (stats['limit'] as num?)?.toInt() ?? 0;
      final history = _maps(stats['history']);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 12, children: [for (final item in {'characters': chars, 'requests': month['requests'], 'cache_entries': stats['cache_entries'], 'cache_chars': stats['cache_chars'], 'cache_hits': stats['cache_hits'], 'same_language': stats['same_language']}.entries) SizedBox(width: 190, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.translation.kpi.${item.key}'.tr()), Text(NumberFormat.decimalPattern(context.locale.toString()).format((item.value as num?) ?? 0), style: context.textStyles.headlineSmall)]))))]),
        const SizedBox(height: 16), Text('admin.translation.monthly'.tr(namedArgs: {'used': '$chars', 'limit': '$limit'})), LinearProgressIndicator(value: limit <= 0 ? 0 : (chars / limit).clamp(0, 1), color: limit > 0 && chars / limit >= .8 ? Theme.of(context).colorScheme.error : null),
        const SizedBox(height: 16), Text('admin.translation.history'.tr(), style: context.textStyles.titleMedium), if (history.isNotEmpty) HbBarChart(points: [for (var index = 0; index < history.length; index++) HbBarChartPoint(day: DateTime.tryParse('${history[index]['month'] ?? ''}-01') ?? DateTime(2000, index + 1), value: (history[index]['chars'] as num?)?.toInt() ?? 0, label: history[index]['month']?.toString())]),
        const SizedBox(height: 16), for (final key in const ['by_type','by_target','by_source','top_users_30d']) ...[TranslationStatsTable(titleKey: key, rows: _maps(stats[key])), const SizedBox(height: 16)],
        const DeepLUsageCard(), const SizedBox(height: 16), TranslationSettingsForm(initial: Map<String, dynamic>.from(stats['settings'] as Map? ?? const {})),
      ]);
    },
  );
}

class TranslationStatsTable extends StatelessWidget {
  final String titleKey; final List<Map<String, dynamic>> rows;
  const TranslationStatsTable({super.key, required this.titleKey, required this.rows});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.translation.table.$titleKey'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: 8), if (rows.isEmpty) Text('admin.translation.empty'.tr()) else for (final row in rows) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text((row['type'] ?? row['target_lang'] ?? row['source_lang'] ?? row['username'] ?? '').toString())), Text(NumberFormat.decimalPattern(context.locale.toString()).format((row['chars'] ?? row['requests'] ?? 0) as num))]))]);
}

class DeepLUsageCard extends ConsumerWidget {
  const DeepLUsageCard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => Card(child: Padding(padding: const EdgeInsets.all(16), child: ref.watch(adminDeeplUsageProvider).when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('admin.translation.deepl_error'.tr()), data: (value) => Row(children: [Expanded(child: Text('admin.translation.deepl_usage'.tr(namedArgs: {'used': '${value['character_count'] ?? 0}', 'limit': '${value['character_limit'] ?? 0}'}))), HBButton.soft(label: 'common.refresh'.tr(), onPressed: () => ref.invalidate(adminDeeplUsageProvider))]))));
}

class TranslationSettingsForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> initial;
  const TranslationSettingsForm({super.key, required this.initial});
  @override ConsumerState<TranslationSettingsForm> createState() => _TranslationSettingsFormState();
}
class _TranslationSettingsFormState extends ConsumerState<TranslationSettingsForm> {
  late bool enabled = widget.initial['enabled'] as bool? ?? true;
  late String formality = widget.initial['formality']?.toString() ?? 'default';
  late Set<String> types = Set<String>.from(widget.initial['content_types'] as List? ?? const ['post','comment','message','article','listing','event']);
  late final monthly = TextEditingController(text: '${widget.initial['monthly_chars_limit'] ?? 0}');
  late final daily = TextEditingController(text: '${widget.initial['per_user_daily_chars'] ?? 0}');
  @override void dispose() { monthly.dispose(); daily.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.translation.settings'.tr(), style: context.textStyles.titleMedium), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('admin.translation.enabled'.tr()), value: enabled, onChanged: (value) => setState(() => enabled = value)), Row(children: [Expanded(child: HBInput(controller: monthly, label: 'admin.translation.monthly_limit'.tr())), const SizedBox(width: 12), Expanded(child: HBInput(controller: daily, label: 'admin.translation.daily_limit'.tr()))]), const SizedBox(height: 12), Wrap(spacing: 8, children: [for (final item in const ['default','prefer_more','prefer_less']) HBChip(label: 'admin.translation.formality.$item'.tr(), selected: formality == item, onTap: () => setState(() => formality = item))]), const SizedBox(height: 12), Wrap(spacing: 8, children: [for (final item in const ['post','comment','message','article','listing','event']) HBChip(label: 'admin.translation.type.$item'.tr(), selected: types.contains(item), onTap: () => setState(() => types.contains(item) ? types.remove(item) : types.add(item)))]), const SizedBox(height: 12), Row(children: [HBButton.primary(label: 'common.save'.tr(), onPressed: save), const SizedBox(width: 8), HBButton.ghost(label: 'admin.translation.flag'.tr(), onPressed: () => context.go('/admin/system'))])])));
  Future<void> save() async { await ref.read(adminP43RepositoryProvider).saveSetting('translation', {'enabled': enabled, 'monthly_chars_limit': int.tryParse(monthly.text) ?? 0, 'per_user_daily_chars': int.tryParse(daily.text) ?? 0, 'formality': formality, 'content_types': types.toList()}); ref.invalidate(adminTranslationStatsProvider); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.system.saved'.tr()))); }
}

List<Map<String, dynamic>> _maps(Object? value) => [for (final row in value as List? ?? const []) Map<String, dynamic>.from(row as Map)];

class TranslationOverrideDialog extends ConsumerStatefulWidget {
  final AdminTranslationOverride? existing; final List<String> assetKeys;
  const TranslationOverrideDialog({super.key, this.existing, this.assetKeys = const []});
  @override ConsumerState<TranslationOverrideDialog> createState() => _TranslationOverrideDialogState();
}
class _TranslationOverrideDialogState extends ConsumerState<TranslationOverrideDialog> {
  late final key = TextEditingController(text: widget.existing?.key); late final value = TextEditingController(text: widget.existing?.value); late String locale = widget.existing?.locale ?? 'it'; bool saving = false;
  @override void dispose() { key.dispose(); value.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text((widget.existing == null ? 'admin.l10n.add' : 'admin.l10n.edit').tr()), content: SizedBox(width: 620, child: Column(mainAxisSize: MainAxisSize.min, children: [if (widget.assetKeys.isNotEmpty) Autocomplete<String>(optionsBuilder: (text) => widget.assetKeys.where((item) => item.contains(text.text)).take(20), onSelected: (item) => key.text = item, fieldViewBuilder: (_,controller,focus,onSubmit) { controller.text = key.text; controller.addListener(() => key.text = controller.text); return TextField(controller: controller, focusNode: focus, decoration: InputDecoration(labelText: 'admin.l10n.key'.tr())); }), if (widget.assetKeys.isEmpty) HBInput(controller: key, label: 'admin.l10n.key'.tr(), enabled: widget.existing == null), const SizedBox(height: 12), Wrap(spacing: 8, children: [for (final item in const ['it','en','fr','es','de']) HBChip(label: item.toUpperCase(), selected: locale == item, onTap: widget.existing == null ? () => setState(() => locale = item) : null)]), const SizedBox(height: 12), HBInput(controller: value, label: 'admin.l10n.value'.tr(), maxLines: 6)])), actions: [if (widget.existing != null) HBButton.ghost(label: 'common.delete'.tr(), onPressed: remove), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: save)]);
  Future<void> save() async { setState(() => saving = true); try { await ref.read(adminP43RepositoryProvider).upsertTranslation(locale,key.text,value.text); if (mounted) context.pop(); } catch (error) { if (mounted) p43Error(context,error); } finally { if (mounted) setState(() => saving=false); } }
  Future<void> remove() async { try { await ref.read(adminP43RepositoryProvider).deleteTranslation(locale,key.text); if (mounted) context.pop(); } catch (error) { if (mounted) p43Error(context,error); } }
}