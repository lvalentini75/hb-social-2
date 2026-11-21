import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_p43_models.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p43_providers.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/features/admin/presentation/admin_release_panels.dart';

class AdminSystemPage extends ConsumerStatefulWidget {
  const AdminSystemPage({super.key});
  @override ConsumerState<AdminSystemPage> createState() => _AdminSystemPageState();
}
class _AdminSystemPageState extends ConsumerState<AdminSystemPage> {
  int tab = 0;
  @override Widget build(BuildContext context) => AdminListPage(title: 'admin.system.title'.tr(), description: 'admin.system.subtitle'.tr(), filters: HBSegmentedTabs(labels: ['admin.flags.title'.tr(),'admin.email.title'.tr(),'admin.jobs.title'.tr(),'admin.system.observability'.tr(),'admin.auth.title'.tr(),'admin.release.title'.tr(),'admin.legal.title'.tr(),'admin.release.checklist'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)), emptyMessage: '', content: switch (tab) { 0 => const AdminFeatureFlagsPanel(), 1 => const AdminEmailPanel(), 2 => const AdminJobsPanel(), 3 => const AdminObservabilityPanel(), 4 => const AdminAuthPanel(), 5 => const AdminReleasePanel(), 6 => const AdminLegalPanel(), _ => const AdminLaunchChecklistPanel() });
}

class AdminAuthPanel extends ConsumerStatefulWidget {
  const AdminAuthPanel({super.key});
  @override ConsumerState<AdminAuthPanel> createState() => _AdminAuthPanelState();
}

class _AdminAuthPanelState extends ConsumerState<AdminAuthPanel> {
  int days = 30;
  bool loaded = false, saving = false, emailPassword = true, magicLink = false, manualLinking = false;
  List<String> order = const [];
  Map<String, Map<String, dynamic>> providers = {};
  DateTime? appleRenewBy;

  @override Widget build(BuildContext context) {
    final stats = ref.watch(adminAuthStatsProvider(days));
    final superadmin = ref.watch(adminAccessProvider).value?.roleName == 'superadmin';
    stats.whenData((value) { if (!loaded) WidgetsBinding.instance.addPostFrameCallback((_) => _load(value.settings)); });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerLeft, child: HBSegmentedTabs(labels: ['7','30','90'], selectedIndex: [7,30,90].indexOf(days), onChanged: (index) => setState(() => days = [7,30,90][index]))), const SizedBox(height: AppSpacing.md),
      stats.when(loading: () => const LinearProgressIndicator(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.auth.error'.tr(), message: 'errors.network'.tr()), data: (value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [AdminAuthKpi(label: 'admin.auth.total_users'.tr(), value: value.totalUsers), AdminAuthKpi(label: 'admin.auth.with_password'.tr(), value: value.withPassword), AdminAuthKpi(label: 'admin.auth.social_only'.tr(), value: value.socialOnly), AdminAuthKpi(label: 'admin.auth.signups'.tr(namedArgs: {'days':'${value.periodDays}'}), value: value.signupsPeriod)]),
        const SizedBox(height: AppSpacing.md), AdminDataTable(headers: ['admin.auth.provider'.tr(),'admin.auth.users'.tr(),'admin.auth.new_period'.tr(),'admin.auth.active_period'.tr()], emptyMessage: 'admin.auth.empty'.tr(), rows: [for (final row in value.byProvider) [Text('auth.social.provider.${row['provider']}'.tr()), Text('${row['users'] ?? 0}'), Text('${row['new_in_period'] ?? 0}'), Text('${row['active_in_period'] ?? 0}')]]),
      ])),
      const SizedBox(height: AppSpacing.lg), Text('admin.auth.settings'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm),
      HBCard(child: IgnorePointer(ignoring: !superadmin, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final provider in order) AdminAuthProviderRow(provider: provider, value: providers[provider] ?? const {}, onChanged: (value) => setState(() => providers[provider] = value), onMove: (delta) => _move(provider, delta)),
        SwitchListTile(value: emailPassword, onChanged: (value) => setState(() => emailPassword = value), title: Text('admin.auth.email_password'.tr())),
        SwitchListTile(value: magicLink, onChanged: (value) => setState(() => magicLink = value), title: Text('admin.auth.magic_link'.tr())),
        SwitchListTile(value: manualLinking, onChanged: (value) => setState(() => manualLinking = value), title: Text('admin.auth.manual_linking'.tr())),
        Row(children: [Expanded(child: Text(appleRenewBy == null ? 'admin.auth.apple_secret_empty'.tr() : 'admin.auth.apple_secret_date'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).format(appleRenewBy!)}))), HBButton.soft(label: 'admin.auth.choose_date'.tr(), onPressed: _pickAppleDate)]),
        if (_appleWarning) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: HBStatusChip(kind: HBStatusKind.pending, label: 'admin.auth.apple_secret_warning'.tr())),
        const SizedBox(height: AppSpacing.md), Text('admin.auth.supabase_note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)),
        if (superadmin) Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: save)),
      ]))),
    ]);
  }

  bool get _appleWarning {
    if (providers['apple']?['enabled'] != true) return false;
    return appleRenewBy == null || appleRenewBy!.difference(DateTime.now()).inDays < 30;
  }

  void _load(Map<String, dynamic> settings) {
    if (!mounted || loaded) return;
    final raw = Map<String, dynamic>.from(settings['providers'] as Map? ?? const {});
    setState(() {
      loaded = true; order = [for (final value in settings['order'] as List? ?? raw.keys) value.toString()];
      providers = {for (final entry in raw.entries) entry.key: Map<String, dynamic>.from(entry.value as Map? ?? const {})};
      emailPassword = settings['email_password'] != false; magicLink = settings['magic_link'] == true; manualLinking = settings['manual_linking'] == true;
      appleRenewBy = DateTime.tryParse(settings['apple_secret_renew_by']?.toString() ?? '');
    });
  }

  void _move(String provider, int delta) { final index = order.indexOf(provider); final next = index + delta; if (next < 0 || next >= order.length) return; setState(() { final updated = [...order]; final item = updated.removeAt(index); updated.insert(next, item); order = updated; }); }
  Future<void> _pickAppleDate() async { final value = await showDatePicker(context: context, initialDate: appleRenewBy ?? DateTime.now().add(const Duration(days: 150)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730))); if (value != null && mounted) setState(() => appleRenewBy = value); }
  Future<void> save() async {
    setState(() => saving = true);
    try { await ref.read(adminP43RepositoryProvider).saveAuthSettings({'providers': providers, 'order': order, 'email_password': emailPassword, 'magic_link': magicLink, 'manual_linking': manualLinking, 'apple_secret_renew_by': appleRenewBy?.toIso8601String().split('T').first}); ref.invalidate(adminAuthStatsProvider); ref.invalidate(platformConfigProvider); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.system.saved'.tr()))); }
    catch (error) { if (mounted) p43Error(context, error); }
    finally { if (mounted) setState(() => saving = false); }
  }
}

class AdminAuthKpi extends StatelessWidget {
  final String label; final int value;
  const AdminAuthKpi({super.key, required this.label, required this.value});
  @override Widget build(BuildContext context) => SizedBox(width: 190, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: context.textStyles.bodySmall), Text('$value', style: context.textStyles.headlineSmall?.bold)])));
}

class AdminAuthProviderRow extends StatelessWidget {
  final String provider; final Map<String, dynamic> value; final ValueChanged<Map<String, dynamic>> onChanged; final ValueChanged<int> onMove;
  const AdminAuthProviderRow({super.key, required this.provider, required this.value, required this.onChanged, required this.onMove});
  @override Widget build(BuildContext context) {
    final platforms = [for (final item in value['platforms'] as List? ?? const []) item.toString()];
    return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Column(children: [Row(children: [Expanded(child: Text('auth.social.provider.$provider'.tr(), style: context.textStyles.bodyMedium?.bold)), HBButton.icon(icon: Icons.arrow_upward, size: HBButtonSize.sm, onPressed: () => onMove(-1)), HBButton.icon(icon: Icons.arrow_downward, size: HBButtonSize.sm, onPressed: () => onMove(1)), Switch(value: value['enabled'] == true, onChanged: (enabled) => onChanged({...value, 'enabled': enabled}))]), Wrap(spacing: AppSpacing.sm, children: [for (final platform in const ['web','ios','android']) HBChip(label: 'admin.auth.platform.$platform'.tr(), selected: platforms.contains(platform), onTap: () { final next = [...platforms]; next.contains(platform) ? next.remove(platform) : next.add(platform); onChanged({...value, 'platforms': next}); })]), if (provider == 'apple') SwitchListTile(contentPadding: EdgeInsets.zero, value: value['native_ios'] == true, onChanged: (enabled) => onChanged({...value, 'native_ios': enabled}), title: Text('admin.auth.native_apple'.tr()))]));
  }
}

class AdminFeatureFlagsPanel extends ConsumerWidget {
  const AdminFeatureFlagsPanel({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBCard(color: LightModeColors.boscoTint, child: Text('admin.flags.deterministic'.tr())), const SizedBox(height: 12), ref.watch(adminFeatureFlagsProvider).when(loading: () => const AdminDataTable(headers: ['','','','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.flags.error'.tr(), message: 'admin.flags.error_help'.tr()), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.flag_outlined, title: 'admin.flags.empty'.tr(), message: 'admin.flags.empty_help'.tr()) : Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 8), child: AdminFeatureFlagRow(item: item))]))]);
}

class AdminFeatureFlagRow extends ConsumerStatefulWidget {
  final AdminFeatureFlagRecord item;
  const AdminFeatureFlagRow({super.key, required this.item});
  @override ConsumerState<AdminFeatureFlagRow> createState() => _AdminFeatureFlagRowState();
}
class _AdminFeatureFlagRowState extends ConsumerState<AdminFeatureFlagRow> {
  late bool enabled = widget.item.enabled; late double rollout = widget.item.rollout.toDouble(); bool saving = false;
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('${widget.item.module} · ${widget.item.countryCode ?? 'admin.flags.global'.tr()}', style: context.textStyles.titleMedium)), Switch(value: enabled, onChanged: (value) => setState(() => enabled = value))]), Slider(value: rollout, min: 0, max: 100, divisions: 20, label: '${rollout.round()}%', onChanged: (value) => setState(() => rollout = value)), Text('admin.flags.users'.tr(namedArgs: {'enabled': '${widget.item.enabledUsers}', 'eligible': '${widget.item.eligibleUsers}'})), Text('admin.flags.updated'.tr(namedArgs: {'time': relativeTime(context, widget.item.updatedAt)})), Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), size: HBButtonSize.sm, isLoading: saving, onPressed: save))]));
  Future<void> save() async { setState(() => saving = true); try { await ref.read(adminP43RepositoryProvider).upsertFlag(country: widget.item.countryCode, module: widget.item.module, enabled: enabled, rollout: rollout.round(), description: widget.item.description); ref.invalidate(adminFeatureFlagsProvider); } catch (error) { if (mounted) p43Error(context, error); } finally { if (mounted) setState(() => saving = false); } }
}

class AdminEmailPanel extends ConsumerStatefulWidget { const AdminEmailPanel({super.key}); @override ConsumerState<AdminEmailPanel> createState() => _AdminEmailPanelState(); }
class _AdminEmailPanelState extends ConsumerState<AdminEmailPanel> {
  bool outbox = false; String? status;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [HBSegmentedTabs(labels: ['admin.email.templates'.tr(),'admin.email.outbox'.tr()], selectedIndex: outbox ? 1 : 0, onChanged: (value) => setState(() => outbox = value == 1)), const Spacer(), if (outbox) HBButton.primary(label: 'admin.email.dispatch'.tr(), size: HBButtonSize.sm, onPressed: dispatch)]), const SizedBox(height: 12), if (!outbox) ref.watch(adminEmailTemplatesProvider).when(loading: () => const AdminDataTable(headers: ['','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.email.error'.tr(), message: 'admin.email.error_help'.tr()), data: (items) => AdminDataTable(headers: ['admin.email.key'.tr(),'admin.email.language'.tr(),'admin.email.stats'.tr(),'admin.email.status'.tr()], emptyMessage: 'admin.email.empty'.tr(), rows: [for (final item in items) [Text(item.key), Text(item.locale.toUpperCase()), Text('${item.sent30d} / ${item.failed30d} / ${item.queued}'), HBStatusChip(kind: item.enabled ? HBStatusKind.approved : HBStatusKind.neutral, label: (item.enabled ? 'admin.system.active' : 'admin.system.inactive').tr())]])) else FutureBuilder(future: ref.read(adminP43RepositoryProvider).emailOutbox(status: status), builder: (context, snapshot) { final rows = snapshot.data ?? const <Map<String,dynamic>>[]; return AdminDataTable(headers: ['admin.email.date'.tr(),'admin.email.recipient'.tr(),'admin.email.key'.tr(),'admin.email.status'.tr(),'admin.email.attempts'.tr()], emptyMessage: 'admin.email.outbox_empty'.tr(), isLoading: snapshot.connectionState == ConnectionState.waiting, rows: [for (final row in rows) [Text(row['created_at']?.toString() ?? ''), Text(row['to_email']?.toString() ?? ''), Text(row['template_key']?.toString() ?? ''), Text(row['status']?.toString() ?? ''), Text(row['attempts']?.toString() ?? '0')]]); })]);
  Future<void> dispatch() async { try { final result = await ref.read(adminP43RepositoryProvider).dispatchEmail(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.email.dispatched'.tr(namedArgs: {'sent':'${result['sent'] ?? 0}','failed':'${result['failed'] ?? 0}'})))); } catch (error) { if (mounted) p43Error(context, error); } }
}

class AdminJobsPanel extends ConsumerWidget {
  const AdminJobsPanel({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adminCronJobsProvider).when(loading: () => const AdminDataTable(headers: ['','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.jobs.error'.tr(), message: 'admin.jobs.error_help'.tr()), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.schedule_outlined, title: 'admin.jobs.empty'.tr(), message: 'admin.jobs.empty_help'.tr()) : Column(children: [for (final item in items) AdminCronJobRow(item: item)]));
}
class AdminCronJobRow extends ConsumerWidget {
  final AdminCronJob item; const AdminCronJobRow({super.key, required this.item});
  @override Widget build(BuildContext context, WidgetRef ref) => Padding(padding: const EdgeInsets.only(bottom: 8), child: HBCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: context.textStyles.titleMedium), Text('${item.schedule} · ${item.runs24h} / ${item.failed24h}'), if (item.lastMessage != null) Text(item.lastMessage!, maxLines: 1, overflow: TextOverflow.ellipsis)])), Switch(value: item.active, onChanged: (value) async { await ref.read(adminP43RepositoryProvider).toggleCron(item.name, value); ref.invalidate(adminCronJobsProvider); }), HBButton.soft(label: 'admin.jobs.run'.tr(), size: HBButtonSize.sm, onPressed: () async { try { final result = await ref.read(adminP43RepositoryProvider).runCron(item.name); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.jobs.ran'.tr(namedArgs: {'ms':'${result['ms'] ?? 0}'})))); } catch (error) { if (context.mounted) p43Error(context, error); } })])));
}

class AdminObservabilityPanel extends ConsumerStatefulWidget { const AdminObservabilityPanel({super.key}); @override ConsumerState<AdminObservabilityPanel> createState() => _AdminObservabilityPanelState(); }
class _AdminObservabilityPanelState extends ConsumerState<AdminObservabilityPanel> {
  final dsn = TextEditingController(); final appUrl = TextEditingController(); final sla = TextEditingController(); final autoClose = TextEditingController(); bool enabled = false; double traces = 0; String environment = 'dev'; bool loaded = false;
  @override void dispose() { dsn.dispose(); appUrl.dispose(); sla.dispose(); autoClose.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { if (!loaded) { loaded = true; load(); } final superadmin = ref.watch(adminAccessProvider).value?.roleName == 'superadmin'; return Column(children: [HBCard(child: IgnorePointer(ignoring: !superadmin, child: Column(children: [SwitchListTile(title: Text('admin.system.sentry_enabled'.tr()), value: enabled, onChanged: (value) => setState(() => enabled = value)), HBFormField(label: 'admin.system.sentry_dsn'.tr(), child: HBInput(controller: dsn)), Wrap(children: [for (final item in const ['dev','staging','prod']) ChoiceChip(label: Text(item), selected: environment == item, onSelected: (_) => setState(() => environment = item))]), Slider(value: traces, min: 0, max: 1, divisions: 20, onChanged: (value) => setState(() => traces = value)), HBInput(controller: appUrl, label: 'admin.system.app_url'.tr()), Text('admin.system.sentry_note'.tr()), if (superadmin) Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), onPressed: saveObservability))]))), const SizedBox(height: 12), HBCard(child: Column(children: [Text('admin.system.support'.tr(), style: context.textStyles.titleMedium), HBInput(controller: sla, label: 'admin.system.sla'.tr(), keyboardType: TextInputType.number), HBInput(controller: autoClose, label: 'admin.system.auto_close'.tr(), keyboardType: TextInputType.number), Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'common.save'.tr(), onPressed: saveSupport))]))]); }
  Future<void> load() async { final repository = ref.read(adminP43RepositoryProvider); final o = await repository.setting('observability') ?? {}; final s = await repository.setting('support') ?? {}; if (!mounted) return; setState(() { enabled = o['sentry_enabled'] == true; dsn.text = o['sentry_dsn']?.toString() ?? ''; appUrl.text = o['app_url']?.toString() ?? ''; environment = o['environment']?.toString() ?? 'dev'; traces = ((o['traces_sample_rate'] as num?) ?? 0).toDouble(); sla.text = s['sla_hours']?.toString() ?? '24'; autoClose.text = s['auto_close_days']?.toString() ?? '30'; }); }
  Future<void> saveObservability() => run(() => ref.read(adminP43RepositoryProvider).saveSetting('observability', {'sentry_enabled':enabled,'sentry_dsn':dsn.text.trim(),'environment':environment,'traces_sample_rate':traces,'app_url':appUrl.text.trim()}));
  Future<void> saveSupport() => run(() => ref.read(adminP43RepositoryProvider).saveSetting('support', {'sla_hours':int.tryParse(sla.text),'auto_close_days':int.tryParse(autoClose.text),'categories':const ['account','payments','ads','content','bug','other']}));
  Future<void> run(Future<void> Function() action) async { try { await action(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.system.saved'.tr()))); } catch (error) { if (mounted) p43Error(context, error); } }
}

void p43Error(BuildContext context, Object error) { final key = error is AppException ? error.messageKey : 'p43.errors.generic'; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr()))); }