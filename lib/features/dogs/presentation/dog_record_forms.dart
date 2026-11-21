import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';

class DogTrialForm extends ConsumerStatefulWidget {
  final String dogId;
  final DogTrial? initial;
  const DogTrialForm({super.key, required this.dogId, this.initial});
  @override
  ConsumerState<DogTrialForm> createState() => _DogTrialFormState();
}

class _DogTrialFormState extends ConsumerState<DogTrialForm> {
  static const kinds = ['field_trial', 'working_test', 'show', 'exam', 'tracking', 'other'];
  static const quickResults = ['ECC', 'MB', 'B', 'CAC', 'CACIT', 'CQN', 'Brevetto', 'Approvato'];
  late String kind = widget.initial?.kind ?? kinds.first;
  late DateTime date = widget.initial?.trialDate ?? DateTime.now();
  late final title = TextEditingController(text: widget.initial?.title ?? '');
  late final place = TextEditingController(text: widget.initial?.place ?? '');
  late final organizer = TextEditingController(text: widget.initial?.organizer ?? '');
  late final judge = TextEditingController(text: widget.initial?.judge ?? '');
  late final result = TextEditingController(text: widget.initial?.result ?? '');
  late final points = TextEditingController(text: widget.initial?.points ?? '');
  late final notes = TextEditingController(text: widget.initial?.notes ?? '');
  late String? eventId = widget.initial?.eventId;
  late String? certificatePath = widget.initial?.certificatePath;
  Uint8List? documentBytes;
  String? documentExtension;
  double progress = 0;
  bool saving = false;
  String? errorKey;

  @override
  void dispose() { for (final item in [title, place, organizer, judge, result, points, notes]) { item.dispose(); } super.dispose(); }

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(1980), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (value != null) setState(() => date = value);
  }

  Future<void> _pickCertificate() async {
    final value = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'], withData: true);
    if (value == null) return;
    final file = value.files.single;
    if (file.bytes == null) { setState(() => errorKey = 'errors.file_unreadable'); return; }
    if (file.size > 10 * 1024 * 1024) { setState(() => errorKey = 'errors.file_too_large'); return; }
    setState(() { documentBytes = file.bytes; documentExtension = file.extension; errorKey = null; });
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) { setState(() => errorKey = 'dogs.errors.name_invalid'); return; }
    setState(() { saving = true; errorKey = null; });
    try {
      final repository = ref.read(dogsRepositoryProvider);
      if (documentBytes != null) certificatePath = await repository.uploadCertificate(widget.dogId, documentBytes!, documentExtension ?? '', (value) { if (mounted) setState(() => progress = value); });
      await repository.upsertTrial(DogTrialInput(dogId: widget.dogId, id: widget.initial?.id, kind: kind, title: title.text, date: date, place: place.text, organizer: organizer.text, judge: judge.text, result: result.text, points: points.text, notes: notes.text, eventId: eventId, certificatePath: certificatePath));
      ref.invalidate(dogProfileProvider(widget.dogId)); ref.invalidate(myDogsProvider);
      if (mounted) context.pop();
    } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(dogTrialEventsProvider).value ?? const <DogEventChoice>[];
    return SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text((widget.initial == null ? 'dogs.trials.add' : 'dogs.trials.edit').tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md),
      HBFormSection(title: 'dogs.trials.section'.tr(), children: [
        HBFormField(label: 'dogs.trials.kind'.tr(), required: true, child: HBChoice<String>(options: kinds, value: kind, onChanged: (value) => setState(() => kind = value), labelBuilder: (value) => 'dogs.trials.kinds.$value'.tr())),
        HBFormField(label: 'dogs.trials.title'.tr(), required: true, child: HBInput(controller: title, maxLength: 120)),
        HBFormField(label: 'dogs.trials.date'.tr(), required: true, child: HBButton.secondary(label: DateFormat.yMMMd(context.locale.languageCode).format(date), onPressed: _pickDate)),
        HBFormField(label: 'dogs.trials.place'.tr(), child: HBInput(controller: place)), HBFormField(label: 'dogs.trials.organizer'.tr(), child: HBInput(controller: organizer)), HBFormField(label: 'dogs.trials.judge'.tr(), child: HBInput(controller: judge)),
        HBFormField(label: 'dogs.trials.result'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBInput(controller: result, maxLength: 60), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in quickResults) HBChip(label: value, selected: result.text == value, onTap: () => setState(() => result.text = value))])])),
        HBFormField(label: 'dogs.trials.points'.tr(), child: HBInput(controller: points, maxLength: 40)), HBFormField(label: 'dogs.trials.notes'.tr(), child: HBInput(controller: notes, maxLength: 1000, maxLines: 4)),
        HBFormField(label: 'dogs.trials.event'.tr(), child: HBSelect<String?>(value: eventId, options: [HBSelectOption<String?>(value: null, label: 'dogs.trials.no_event'.tr()), for (final event in events) HBSelectOption<String?>(value: event.id, label: event.title)], onChanged: (value) => setState(() => eventId = value))),
        HBFormField(label: 'dogs.trials.certificate'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBButton.secondary(label: documentBytes != null || certificatePath != null ? 'dogs.trials.certificate_selected'.tr() : 'dogs.trials.choose_certificate'.tr(), icon: Icons.attach_file_rounded, onPressed: saving ? null : _pickCertificate), if (saving && documentBytes != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: HBUploadProgress(progress: progress))])),
      ]),
      if (errorKey != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))), const SizedBox(height: AppSpacing.md),
      HBButton.primary(label: 'common.save'.tr(), onPressed: saving ? null : _save, isLoading: saving),
    ]))));
  }
}

class DogHealthForm extends ConsumerStatefulWidget {
  final String dogId;
  final DogHealthRecord? initial;
  const DogHealthForm({super.key, required this.dogId, this.initial});
  @override
  ConsumerState<DogHealthForm> createState() => _DogHealthFormState();
}

class _DogHealthFormState extends ConsumerState<DogHealthForm> {
  static const kinds = ['vaccine', 'antiparasitic', 'visit', 'surgery', 'medication', 'other'];
  late String kind = widget.initial?.kind ?? kinds.first;
  late DateTime performedOn = widget.initial?.performedOn ?? DateTime.now();
  late DateTime? dueOn = widget.initial?.dueOn;
  late final title = TextEditingController(text: widget.initial?.title ?? '');
  late final vet = TextEditingController(text: widget.initial?.vetName ?? '');
  late final notes = TextEditingController(text: widget.initial?.notes ?? '');
  bool saving = false;
  String? errorKey;
  @override
  void dispose() { title.dispose(); vet.dispose(); notes.dispose(); super.dispose(); }
  Future<void> _date(bool due) async { final initial = due ? dueOn ?? _suggestedDue() : performedOn; final value = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1980), lastDate: DateTime(2100)); if (value != null) setState(() { if (due) { dueOn = value; } else { performedOn = value; } }); }
  DateTime _suggestedDue() => kind == 'vaccine' ? DateTime(performedOn.year + 1, performedOn.month, performedOn.day) : kind == 'antiparasitic' ? DateTime(performedOn.year, performedOn.month + 1, performedOn.day) : performedOn;
  Future<void> _save() async { if (title.text.trim().isEmpty) { setState(() => errorKey = 'dogs.errors.name_invalid'); return; } setState(() { saving = true; errorKey = null; }); try { await ref.read(dogsRepositoryProvider).upsertHealth(DogHealthInput(dogId: widget.dogId, id: widget.initial?.id, kind: kind, title: title.text, performedOn: performedOn, dueOn: dueOn, vetName: vet.text, notes: notes.text)); ref.invalidate(dogProfileProvider(widget.dogId)); ref.invalidate(dogRemindersProvider); ref.invalidate(urgentDogReminderCountProvider); if (mounted) context.pop(); } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); } finally { if (mounted) setState(() => saving = false); } }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text((widget.initial == null ? 'dogs.health.add' : 'dogs.health.edit').tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBFormSection(title: 'dogs.health.section'.tr(), children: [HBFormField(label: 'dogs.health.kind'.tr(), child: HBChoice<String>(options: kinds, value: kind, onChanged: (value) => setState(() { kind = value; if (dueOn == null && const {'vaccine', 'antiparasitic'}.contains(value)) dueOn = _suggestedDue(); }), labelBuilder: (value) => 'dogs.health.kinds.$value'.tr())), HBFormField(label: 'dogs.health.title'.tr(), required: true, child: HBInput(controller: title, maxLength: 120)), HBFormField(label: 'dogs.health.performed_on'.tr(), required: true, child: HBButton.secondary(label: DateFormat.yMMMd(context.locale.languageCode).format(performedOn), onPressed: () => _date(false))), HBFormField(label: 'dogs.health.due_on'.tr(), child: Row(children: [Expanded(child: HBButton.secondary(label: dueOn == null ? 'dogs.health.choose_due'.tr() : DateFormat.yMMMd(context.locale.languageCode).format(dueOn!), onPressed: () => _date(true))), if (dueOn != null) HBButton.icon(icon: Icons.close_rounded, onPressed: () => setState(() => dueOn = null))])), HBFormField(label: 'dogs.health.vet'.tr(), child: HBInput(controller: vet)), HBFormField(label: 'dogs.health.notes'.tr(), child: HBInput(controller: notes, maxLines: 4))]), if (errorKey != null) Text(errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError)), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'common.save'.tr(), onPressed: saving ? null : _save, isLoading: saving)]))));
}