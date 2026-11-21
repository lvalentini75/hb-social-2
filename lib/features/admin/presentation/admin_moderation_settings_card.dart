import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/admin/providers/admin_p41_providers.dart';

class AdminModerationSettingsCard extends ConsumerStatefulWidget {
  const AdminModerationSettingsCard({super.key});
  @override ConsumerState<AdminModerationSettingsCard> createState() => _AdminModerationSettingsCardState();
}

class _AdminModerationSettingsCardState extends ConsumerState<AdminModerationSettingsCard> {
  final controllers = <String, TextEditingController>{};
  bool strikeOnRemove = true;
  bool initialized = false;
  bool saving = false;
  @override void dispose() { for (final controller in controllers.values) { controller.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    final value = ref.watch(adminModerationSettingsProvider);
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.reports.settings.title'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.md), value.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('errors.network'.tr()), data: (settings) { if (!initialized) { final sla = settings['sla_hours'] is Map ? Map<String, dynamic>.from(settings['sla_hours'] as Map) : <String,dynamic>{}; for (final entry in {'high': sla['high'] ?? 4, 'medium': sla['medium'] ?? 24, 'low': sla['low'] ?? 72, 'default_strike_days': settings['default_strike_days'] ?? 30, 'export_ttl_days': settings['export_ttl_days'] ?? 7, 'self_export_cooldown_days': settings['self_export_cooldown_days'] ?? 7, 'deletion_grace_days': settings['deletion_grace_days'] ?? 14}.entries) { controllers[entry.key] = TextEditingController(text: '${entry.value}'); } strikeOnRemove = settings['strike_on_remove'] as bool? ?? true; initialized = true; } return Column(children: [Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final key in ['high','medium','low','default_strike_days','export_ttl_days','self_export_cooldown_days','deletion_grace_days']) SizedBox(width: 190, child: HBInput(controller: controllers[key], label: 'admin.reports.settings.$key'.tr(), keyboardType: TextInputType.number))]), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('admin.reports.settings.strike_on_remove'.tr()), value: strikeOnRemove, onChanged: (value) => setState(() => strikeOnRemove = value)), Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: saving ? null : _save))]); })]));
  }
  Future<void> _save() async { final values = {for (final entry in controllers.entries) entry.key: int.tryParse(entry.value.text)}; if (values.values.any((value) => value == null || value! <= 0)) return; setState(() => saving = true); try { await ref.read(adminP41RepositoryProvider).saveModerationSettings({'sla_hours': {'high': values['high'], 'medium': values['medium'], 'low': values['low']}, 'strike_on_remove': strikeOnRemove, 'default_strike_days': values['default_strike_days'], 'export_ttl_days': values['export_ttl_days'], 'self_export_cooldown_days': values['self_export_cooldown_days'], 'deletion_grace_days': values['deletion_grace_days']}); ref.invalidate(adminModerationSettingsProvider); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.reports.settings.saved'.tr()))); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class AdminModerationSettingsPage extends StatelessWidget {
  const AdminModerationSettingsPage({super.key});
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('p42.system.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('p42.system.subtitle'.tr()), const SizedBox(height: AppSpacing.lg), const AdminModerationSettingsCard()]))]);
}