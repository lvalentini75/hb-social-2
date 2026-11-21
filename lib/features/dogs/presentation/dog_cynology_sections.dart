import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_record_forms.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class DogNextDueCard extends StatelessWidget {
  final DogHealthRecord record;
  const DogNextDueCard({super.key, required this.record});
  @override
  Widget build(BuildContext context) => HBCard(child: Row(children: [const Icon(Icons.notifications_active_outlined, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('dogs.health.next_due'.tr(namedArgs: {'title': record.title, 'date': DateFormat.yMMMd(context.locale.languageCode).format(record.dueOn!)}), style: context.textStyles.titleSmall))]));
}

class DogTrialsSection extends ConsumerWidget {
  final DogProfile profile;
  const DogTrialsSection({super.key, required this.profile});

  Future<void> _form(BuildContext context, DogTrial? trial) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: DogTrialForm(dogId: profile.dog.id, initial: trial)));
  Future<void> _openCertificate(BuildContext context, WidgetRef ref, DogTrial trial) async {
    if (!profile.isOwner || trial.certificatePath == null) return;
    try { final url = await ref.read(dogsRepositoryProvider).certificateUrl(trial.certificatePath!); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
    on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  Future<void> _delete(BuildContext context, WidgetRef ref, DogTrial trial) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('dogs.trials.delete_title'.tr()), content: Text('dogs.trials.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'dogs.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(dogsRepositoryProvider).deleteTrial(trial.id); ref.invalidate(dogProfileProvider(profile.dog.id)); ref.invalidate(myDogsProvider); }
    on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trials = [...profile.trials]..sort((a, b) => b.trialDate.compareTo(a.trialDate));
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('dogs.trials.heading'.tr(namedArgs: {'count': '${trials.length}'}), style: context.textStyles.titleMedium)), if (profile.isOwner) HBButton.soft(label: 'dogs.trials.add'.tr(), icon: Icons.add_rounded, size: HBButtonSize.sm, onPressed: () => _form(context, null))]), const SizedBox(height: AppSpacing.md),
      if (trials.isEmpty) HBEmptyState(icon: Icons.military_tech_outlined, title: 'dogs.trials.empty'.tr(), message: 'dogs.trials.empty_message'.tr(), action: profile.isOwner ? HBButton.primary(label: 'dogs.trials.add'.tr(), onPressed: () => _form(context, null)) : null)
      else for (var index = 0; index < trials.length; index++) Padding(padding: EdgeInsets.only(bottom: index == trials.length - 1 ? 0 : AppSpacing.sm), child: DogTrialTile(trial: trials[index], owner: profile.isOwner, onCertificate: () => _openCertificate(context, ref, trials[index]), onEdit: () => _form(context, trials[index]), onDelete: () => _delete(context, ref, trials[index]))),
    ]));
  }
}

class DogTrialTile extends StatelessWidget {
  final DogTrial trial;
  final bool owner;
  final VoidCallback onCertificate, onEdit, onDelete;
  const DogTrialTile({super.key, required this.trial, required this.owner, required this.onCertificate, required this.onEdit, required this.onDelete});
  bool get important => RegExp(r'ECC|CAC|CACIT|1°', caseSensitive: false).hasMatch(trial.result ?? '');
  IconData get icon => switch (trial.kind) { 'field_trial' => Icons.workspace_premium_outlined, 'working_test' => Icons.gps_fixed_rounded, 'show' => Icons.emoji_events_outlined, 'exam' => Icons.card_membership_outlined, 'tracking' => Icons.pets_outlined, _ => Icons.sell_outlined };
  @override
  Widget build(BuildContext context) => HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(trial.title, style: context.textStyles.titleSmall), const SizedBox(height: 2), Text([DateFormat.yMMMd(context.locale.languageCode).format(trial.trialDate), if (trial.place?.isNotEmpty == true) trial.place!].join(' · '), style: context.textStyles.bodySmall), if (trial.judge?.isNotEmpty == true) Text('dogs.trials.judge_value'.tr(namedArgs: {'judge': trial.judge!}), style: context.textStyles.bodySmall), if (trial.result?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: HBBadge.label(label: trial.result!, emphasized: important)), if (trial.eventId != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: InkWell(onTap: () => context.push(AppRoutes.eventDetailPath(trial.eventId!)), child: Text(trial.eventTitle ?? 'dogs.trials.event_link'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightPrimary))))])), if (trial.hasCertificate) IconButton(tooltip: 'dogs.trials.certificate'.tr(), onPressed: owner ? onCertificate : null, icon: const Icon(Icons.attach_file_rounded)), if (owner) PopupMenuButton<String>(onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('dogs.edit'.tr())), PopupMenuItem(value: 'delete', child: Text('dogs.delete'.tr()))]) ]));
}

class DogHealthSection extends ConsumerWidget {
  final DogProfile profile;
  const DogHealthSection({super.key, required this.profile});
  Future<void> _form(BuildContext context, DogHealthRecord? record) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: DogHealthForm(dogId: profile.dog.id, initial: record)));
  Future<void> _delete(BuildContext context, WidgetRef ref, DogHealthRecord record) async { final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('dogs.health.delete_title'.tr()), content: Text('dogs.health.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'dogs.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false; if (!confirmed) return; try { await ref.read(dogsRepositoryProvider).deleteHealth(record.id); ref.invalidate(dogProfileProvider(profile.dog.id)); ref.invalidate(dogRemindersProvider); ref.invalidate(urgentDogReminderCountProvider); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = [...?profile.health]..sort((a, b) => (b.performedOn ?? DateTime(1900)).compareTo(a.performedOn ?? DateTime(1900)));
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('dogs.health.heading'.tr(), style: context.textStyles.titleMedium)), HBButton.soft(label: 'dogs.health.add'.tr(), icon: Icons.add_rounded, size: HBButtonSize.sm, onPressed: () => _form(context, null))]), const SizedBox(height: AppSpacing.md), if (records.isEmpty) HBEmptyState(icon: Icons.health_and_safety_outlined, title: 'dogs.health.empty'.tr(), message: 'dogs.health.empty_message'.tr()) else for (var index = 0; index < records.length; index++) Padding(padding: EdgeInsets.only(bottom: index == records.length - 1 ? 0 : AppSpacing.sm), child: DogHealthTile(record: records[index], onEdit: () => _form(context, records[index]), onDelete: () => _delete(context, ref, records[index]))), const SizedBox(height: AppSpacing.md), Text('dogs.health.private_note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]));
  }
}

class DogHealthTile extends StatelessWidget {
  final DogHealthRecord record;
  final VoidCallback onEdit, onDelete;
  const DogHealthTile({super.key, required this.record, required this.onEdit, required this.onDelete});
  IconData get icon => switch (record.kind) { 'vaccine' => Icons.vaccines_outlined, 'antiparasitic' => Icons.shield_outlined, 'visit' => Icons.medical_services_outlined, 'surgery' => Icons.healing_outlined, 'medication' => Icons.medication_outlined, _ => Icons.sell_outlined };
  @override
  Widget build(BuildContext context) {
    final days = record.dueOn?.difference(DateTime.now()).inDays;
    final status = days == null ? null : days < 0 ? HBStatusKind.rejected : days <= 30 ? HBStatusKind.pending : HBStatusKind.approved;
    return HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(record.title, style: context.textStyles.titleSmall), if (record.performedOn != null) Text(DateFormat.yMMMd(context.locale.languageCode).format(record.performedOn!), style: context.textStyles.bodySmall), if (record.vetName?.isNotEmpty == true) Text(record.vetName!, style: context.textStyles.bodySmall), if (record.dueOn != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: HBStatusChip(kind: status!, label: 'dogs.health.recall'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.languageCode).format(record.dueOn!)}))) ])), PopupMenuButton<String>(onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('dogs.edit'.tr())), PopupMenuItem(value: 'delete', child: Text('dogs.delete'.tr()))]) ]));
  }
}