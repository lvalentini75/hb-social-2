import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/legal/domain/legal_document.dart';
import 'package:hb_social/features/legal/providers/legal_providers.dart';
import 'package:intl/intl.dart';

class LegalConsentGate extends ConsumerWidget {
  final Widget child;
  const LegalConsentGate({super.key, required this.child});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session.value == null) return child;
    final authState = ref.watch(authProfileStateProvider);
    if (authState.value?.needsProfileSetup != false) return child;
    return ref.watch(pendingLegalConsentsProvider(context.locale.languageCode)).when(loading: () => child, error: (_, __) => child, data: (value) => value.pending.isEmpty && value.ageConfirmed ? child : LegalConsentPage(value: value));
  }
}

class LegalConsentPage extends ConsumerStatefulWidget {
  final PendingLegalConsents value;
  const LegalConsentPage({super.key, required this.value});
  @override ConsumerState<LegalConsentPage> createState() => _LegalConsentPageState();
}

class _LegalConsentPageState extends ConsumerState<LegalConsentPage> {
  final accepted = <String>{};
  DateTime? birthDate;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(widget.value.pending.any((item) => item.firstTime) ? 'legal.consent.first_title'.tr() : 'legal.consent.updated_title'.tr(), style: context.textStyles.headlineMedium),
      const SizedBox(height: AppSpacing.sm), Text('legal.consent.message'.tr()),
      if (!widget.value.ageConfirmed) ...[const SizedBox(height: AppSpacing.lg), HBCard(child: Row(children: [Expanded(child: Text(birthDate == null ? 'legal.consent.confirm_age'.tr(namedArgs: {'age': '${widget.value.minAge}'}) : DateFormat.yMd(context.locale.toString()).format(birthDate!))), HBButton.soft(label: 'legal.consent.birth_date'.tr(), onPressed: _pickDate)]))],
      for (final item in widget.value.pending) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: HBCard(child: CheckboxListTile(contentPadding: EdgeInsets.zero, value: accepted.contains(item.kind), onChanged: (value) => setState(() => value == true ? accepted.add(item.kind) : accepted.remove(item.kind)), title: Text(item.title), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (item.summary?.isNotEmpty == true) Text('legal.consent.changes'.tr(namedArgs: {'summary': item.summary!})), TextButton(onPressed: () => context.push('/legal/${item.kind}'), child: Text('legal.read'.tr()))])))),
      const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'legal.consent.accept'.tr(), isLoading: saving, onPressed: accepted.length == widget.value.pending.length && (widget.value.ageConfirmed || birthDate != null) ? _accept : null),
      const SizedBox(height: AppSpacing.sm), HBButton.ghost(label: 'legal.consent.refuse'.tr(), onPressed: saving ? null : _refuse),
    ];
    return ColoredBox(color: LightModeColors.lightBackground, child: SafeArea(child: Center(child: SizedBox(width: 680, child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), shrinkWrap: true, children: children)))));
  }

  Future<void> _pickDate() async { final now = DateTime.now(); final result = await showDatePicker(context: context, initialDate: DateTime(now.year - widget.value.minAge, now.month, now.day), firstDate: DateTime(1900), lastDate: DateTime(now.year - widget.value.minAge, now.month, now.day), locale: context.locale); if (result != null) setState(() => birthDate = result); }
  Future<void> _accept() async { setState(() => saving = true); try { if (!widget.value.ageConfirmed) await ref.read(authRepositoryProvider).completeProfile(birthDate: birthDate); for (final item in widget.value.pending) { await ref.read(legalRepositoryProvider).accept(item.kind, item.version, context.locale.languageCode); } ref.invalidate(pendingLegalConsentsProvider); } finally { if (mounted) setState(() => saving = false); } }
  Future<void> _refuse() async { await ref.read(authRepositoryProvider).signOut(); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('legal.consent.refused'.tr()))); context.go('${AppRoutes.privacySecurity}?deletion=1'); } }
}