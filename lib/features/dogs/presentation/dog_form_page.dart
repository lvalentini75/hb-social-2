import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';

class DogFormPage extends ConsumerWidget {
  final String? dogId;
  const DogFormPage({super.key, this.dogId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dogId == null) return const DogForm();
    return ref.watch(dogProfileProvider(dogId!)).when(loading: () => const PageColumns(center: Center(child: CircularProgressIndicator())), error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.unavailable_title'.tr(), message: 'dogs.unavailable_message'.tr()))), data: (profile) => DogForm(initial: profile.dog));
  }
}

class DogForm extends ConsumerStatefulWidget {
  final Dog? initial;
  const DogForm({super.key, this.initial});
  @override
  ConsumerState<DogForm> createState() => _DogFormState();
}

class _DogFormState extends ConsumerState<DogForm> {
  late final name = TextEditingController(text: widget.initial?.name ?? '');
  late final color = TextEditingController(text: widget.initial?.color ?? '');
  late final weight = TextEditingController(text: widget.initial?.weightKg?.toStringAsFixed(1) ?? '');
  late final description = TextEditingController(text: widget.initial?.description ?? '');
  late final pedigree = TextEditingController(text: widget.initial?.pedigreeNumber ?? '');
  late final microchip = TextEditingController(text: widget.initial?.microchipNumber ?? '');
  late final father = TextEditingController(text: widget.initial?.fatherName ?? '');
  late final mother = TextEditingController(text: widget.initial?.motherName ?? '');
  late final kennel = TextEditingController(text: widget.initial?.kennelName ?? '');
  final breederSearch = TextEditingController();
  late String? breedId = widget.initial?.breedId;
  late String? sex = widget.initial?.sex ?? 'male';
  late DateTime? birthDate = widget.initial?.birthDate;
  late DogVisibility visibility = widget.initial?.visibility ?? DogVisibility.public;
  late String? avatarUrl = widget.initial?.avatarUrl;
  late String? coverUrl = widget.initial?.coverUrl;
  String? breederPageId;
  Uint8List? avatarBytes;
  Uint8List? coverBytes;
  double avatarProgress = 0;
  double coverProgress = 0;
  bool saving = false;
  String? errorKey;

  @override
  void dispose() { for (final controller in [name, color, weight, description, pedigree, microchip, father, mother, kennel, breederSearch]) { controller.dispose(); } super.dispose(); }

  Future<void> _pick(bool cover) async {
    try {
      final service = ref.read(mediaUploadServiceProvider);
      final source = await MediaSourcePicker.imageBytes(context, service);
      if (source == null || !mounted) return;
      final value = await HBImageCropper.show(context, bytes: source, aspectRatio: cover ? 3 : 1, outputWidth: cover ? 1800 : 512, outputHeight: cover ? 600 : 512, circularMask: !cover);
      if (value != null && mounted) setState(() { if (cover) { coverBytes = value; } else { avatarBytes = value; } });
    } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(context: context, initialDate: birthDate ?? DateTime(now.year - 2), firstDate: DateTime(now.year - 25), lastDate: now);
    if (value != null) setState(() => birthDate = value);
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) { setState(() => errorKey = 'dogs.errors.name_invalid'); return; }
    setState(() { saving = true; errorKey = null; avatarProgress = 0; coverProgress = 0; });
    try {
      final repository = ref.read(dogsRepositoryProvider);
      var id = await repository.upsert(_input(widget.initial?.id));
      if (avatarBytes != null) avatarUrl = await repository.uploadAvatar(id, avatarBytes!, (value) { if (mounted) setState(() => avatarProgress = value); });
      if (coverBytes != null) coverUrl = await repository.uploadCover(id, coverBytes!, (value) { if (mounted) setState(() => coverProgress = value); });
      if (avatarBytes != null || coverBytes != null) id = await repository.upsert(_input(id));
      ref.invalidate(myDogsProvider); ref.invalidate(dogProfileProvider(id));
      final ownerId = widget.initial?.ownerId ?? ref.read(dogsRepositoryProvider).currentUserId;
      ref.invalidate(dogsOfProvider(ownerId));
      if (mounted) context.go(AppRoutes.dogDetailPath(id));
    } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); }
    finally { if (mounted) setState(() => saving = false); }
  }

  DogInput _input(String? id) => DogInput(id: id, name: name.text, breedId: breedId == '__other__' ? null : breedId, sex: sex, birthDate: birthDate, description: description.text, color: color.text, weightKg: double.tryParse(weight.text.replaceAll(',', '.')), pedigreeNumber: pedigree.text, microchipNumber: microchip.text, fatherName: father.text, motherName: mother.text, kennelName: kennel.text, breederPageId: breederPageId ?? widget.initial?.breederPageId, avatarUrl: avatarUrl, coverUrl: coverUrl, visibility: visibility);

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final breeds = ref.watch(dogBreedsProvider).value ?? const <DogBreed>[];
    final breedOptions = [for (final breed in breeds) HBSelectOption(value: breed.id, label: breed.localizedName(locale), groupLabel: 'dogs.fci_group_short'.tr(namedArgs: {'group': '${breed.fciGroup}'})), HBSelectOption(value: '__other__', label: 'dogs.mixed_breed'.tr())];
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text((widget.initial == null ? 'dogs.form.new_title' : 'dogs.form.edit_title').tr(), style: context.textStyles.headlineSmall)), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: saving ? null : () => context.pop())]),
      const SizedBox(height: AppSpacing.lg), HBCard(child: Column(children: [
        HBFormSection(title: 'dogs.form.identity'.tr(), children: [
          HBFormField(label: 'dogs.form.name'.tr(), required: true, child: HBInput(controller: name, maxLength: 40, enabled: !saving)),
          HBFormField(label: 'dogs.form.breed'.tr(), child: HBSelect<String>(value: breedId ?? (widget.initial != null && widget.initial!.breedId == null ? '__other__' : null), options: breedOptions, onChanged: saving ? null : (value) => setState(() => breedId = value))),
          HBFormField(label: 'dogs.form.sex'.tr(), child: HBChoice<String>(options: const ['male', 'female'], value: sex ?? 'male', onChanged: (value) => setState(() => sex = value), labelBuilder: (value) => 'dogs.sex.$value'.tr())),
          HBFormField(label: 'dogs.form.birth_date'.tr(), child: Row(children: [Expanded(child: HBButton.secondary(label: birthDate == null ? 'dogs.select_date'.tr() : DateFormat.yMMMd(locale).format(birthDate!), onPressed: saving ? null : _pickBirthDate)), if (birthDate != null) HBButton.icon(icon: Icons.close_rounded, onPressed: () => setState(() => birthDate = null))])),
          HBFormField(label: 'dogs.form.color'.tr(), child: HBInput(controller: color, maxLength: 40, enabled: !saving)),
          HBFormField(label: 'dogs.form.weight'.tr(), child: HBInput(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: !saving)),
          HBFormField(label: 'dogs.form.description'.tr(), child: HBInput(controller: description, maxLength: 2000, maxLines: 6, enabled: !saving)),
        ]), const HBFormSectionDivider(),
        HBFormSection(title: 'dogs.form.pedigree_section'.tr(), children: [
          HBFormField(label: 'dogs.form.pedigree_number'.tr(), child: HBInput(controller: pedigree, hint: 'dogs.form.pedigree_hint'.tr(), enabled: !saving)),
          HBFormField(label: 'dogs.form.microchip'.tr(), child: HBInput(controller: microchip, keyboardType: TextInputType.number, maxLength: 15, inputFormatters: [FilteringTextInputFormatter.digitsOnly], enabled: !saving)),
          HBFormField(label: 'dogs.form.father'.tr(), child: HBInput(controller: father, maxLength: 80, enabled: !saving)),
          HBFormField(label: 'dogs.form.mother'.tr(), child: HBInput(controller: mother, maxLength: 80, enabled: !saving)),
          HBFormField(label: 'dogs.form.kennel'.tr(), child: HBInput(controller: kennel, maxLength: 80, enabled: !saving)),
          HBFormField(label: 'dogs.form.breeder'.tr(), child: HBPlaceField<CommunityPage>(controller: breederSearch, hint: 'dogs.form.breeder_hint'.tr(), enabled: !saving, search: (query) async => [for (final page in await ref.read(pageRepositoryProvider).searchPagesByCategory(query, 'breeder')) HBPlaceSuggestion(value: page, title: page.name, subtitle: page.address)], onSelected: (page) => setState(() => breederPageId = page.id))),
        ]), const HBFormSectionDivider(),
        HBFormSection(title: 'dogs.form.photos'.tr(), children: [LayoutBuilder(builder: (_, constraints) { final avatar = HBImageField(kind: HBImageFieldKind.avatar, imageUrl: avatarUrl, imageBytes: avatarBytes, progress: saving && avatarBytes != null ? avatarProgress : null, onPick: saving ? null : () => _pick(false), onRemove: avatarUrl == null && avatarBytes == null ? null : () => setState(() { avatarUrl = null; avatarBytes = null; }), changeLabel: (avatarUrl == null && avatarBytes == null ? 'dogs.form.add_photo' : 'dogs.form.reposition').tr(), removeLabel: 'common.remove'.tr()); final cover = HBImageField(kind: HBImageFieldKind.cover, imageUrl: coverUrl, imageBytes: coverBytes, progress: saving && coverBytes != null ? coverProgress : null, onPick: saving ? null : () => _pick(true), onRemove: coverUrl == null && coverBytes == null ? null : () => setState(() { coverUrl = null; coverBytes = null; }), changeLabel: (coverUrl == null && coverBytes == null ? 'dogs.form.add_cover' : 'dogs.form.reposition').tr(), removeLabel: 'common.remove'.tr()); return constraints.maxWidth < 560 ? Column(children: [avatar, const SizedBox(height: AppSpacing.md), cover]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatar), const SizedBox(width: AppSpacing.lg), Expanded(child: cover)]); })]),
        const HBFormSectionDivider(), HBFormSection(title: 'dogs.form.visibility'.tr(), children: [HBChoice<DogVisibility>(options: DogVisibility.values, value: visibility, onChanged: (value) => setState(() => visibility = value), labelBuilder: (value) => value.labelKey.tr(), descriptions: {for (final value in DogVisibility.values) value: 'dogs.visibility_description.${value.code}'.tr()})]),
        if (errorKey != null) ...[const SizedBox(height: AppSpacing.md), Text(errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
        if (saving && (avatarBytes != null || coverBytes != null)) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: ((avatarBytes == null ? 0 : avatarProgress) + (coverBytes == null ? 0 : coverProgress)) / ((avatarBytes == null ? 0 : 1) + (coverBytes == null ? 0 : 1)))],
        HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _save, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: saving),
      ])), const SizedBox(height: AppSpacing.xxl),
    ])))))]));
  }
}