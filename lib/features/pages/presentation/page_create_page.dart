import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

class PageCreatePage extends ConsumerStatefulWidget {
  const PageCreatePage({super.key});

  @override
  ConsumerState<PageCreatePage> createState() => _PageCreatePageState();
}

class _PageCreatePageState extends ConsumerState<PageCreatePage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController(text: 'https://');
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  String? _category;
  ReferenceRegion? _region;
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  bool _saving = false;
  bool _publishing = false;
  double _progress = 0;
  String? _errorKey;

  bool get _valid => _name.text.trim().length >= 2 && _name.text.trim().length <= 80 && _description.text.trim().length <= 2000 && _category != null;

  @override
  void dispose() {
    for (final controller in [_name, _description, _website, _phone, _email, _address]) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _pick(bool avatar) async {
    try {
      final service = ref.read(mediaUploadServiceProvider);
      final source = await MediaSourcePicker.imageBytes(context, service);
      if (source == null || !mounted) return;
      final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: avatar ? 1 : 3, outputWidth: avatar ? 512 : 1800, outputHeight: avatar ? 512 : 600, circularMask: avatar);
      if (cropped != null && mounted) setState(() => avatar ? _avatar = service.prepareJpeg(cropped) : _cover = service.prepareJpeg(cropped));
    } on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); }
  }

  Future<UploadedMedia?> _upload(PreparedUpload? source, String userId, int index, int count) async {
    if (source == null) return null;
    final progress = UploadProgress();
    final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (index + value) / count); });
    try { return await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'page-media', userId: userId, upload: source, isPublic: true, progress: progress); }
    finally { await subscription.cancel(); await progress.close(); }
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty || value == 'https://' ? null : value;
  }

  Future<void> _create() async {
    if (!_valid || _saving) return;
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) { context.go(AppRoutes.login); return; }
    setState(() { _saving = true; _publishing = false; _progress = 0; _errorKey = null; });
    UploadedMedia? avatar;
    UploadedMedia? cover;
    final count = [_avatar, _cover].whereType<PreparedUpload>().length;
    var index = 0;
    try {
      avatar = await _upload(_avatar, profile.id, index, count);
      if (_avatar != null) index++;
      cover = await _upload(_cover, profile.id, index, count);
      if (mounted) setState(() { _progress = count == 0 ? 0 : 1; _publishing = true; });
      final created = await ref.read(pageRepositoryProvider).createPage(name: _name.text.trim(), category: _category!, description: _optional(_description), website: _optional(_website), phone: _optional(_phone), email: _optional(_email), address: _optional(_address), regionId: _region?.id, avatarUrl: avatar?.path, coverUrl: cover?.path);
      ref.invalidate(pagesListProvider); ref.invalidate(myPagesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('pages.created'.tr())));
      context.go(AppRoutes.pageDetailPath(created.slug));
    } on AppException catch (error) {
      if (avatar != null) await ref.read(mediaUploadServiceProvider).delete('page-media', avatar.path);
      if (cover != null) await ref.read(mediaUploadServiceProvider).delete('page-media', cover.path);
      if (mounted) setState(() { _saving = false; _publishing = false; _errorKey = error.messageKey; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    if (profile == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'pages.sign_in_title'.tr(), message: 'pages.sign_in_message'.tr(), action: HBButton.primary(label: 'pages.sign_in_cta'.tr(), onPressed: () => context.go(AppRoutes.login)))));
    final categories = ref.watch(pageCategoriesProvider);
    final regions = ref.watch(regionsProvider(profile.countryCode));
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('pages.form.new_title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('pages.form.new_subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))]))),
      const SizedBox(height: AppSpacing.lg),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBFormSection(title: 'pages.form.identity'.tr(), children: [
          PageImagesFormRow(avatar: _avatar, cover: _cover, enabled: !_saving, onPickAvatar: () => _pick(true), onPickCover: () => _pick(false), onRemoveAvatar: () => setState(() => _avatar = null), onRemoveCover: () => setState(() => _cover = null)),
          HBFormField(label: 'pages.form.name'.tr(), required: true, helper: '${_name.text.length}/80', child: HBInput(controller: _name, hint: 'pages.form.name_hint'.tr(), maxLength: 80, enabled: !_saving, onChanged: (_) => setState(() {}))),
          HBFormField(label: 'pages.form.category_label'.tr(), required: true, helper: _category == 'gun_shop' || _category == 'guide' ? 'pages.form.verification_help'.tr() : null, child: categories.isLoading ? const LinearProgressIndicator() : categories.hasError ? Text('pages.errors.categories'.tr()) : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: (categories.value ?? const <PageCategory>[]).map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: _saving ? null : () => setState(() => _category = item.slug))).toList())),
          HBFormField(label: 'pages.form.description'.tr(), helper: '${_description.text.length}/2000', child: HBInput(controller: _description, hint: 'pages.form.description_hint'.tr(), maxLength: 2000, minLines: 3, maxLines: 8, enabled: !_saving, onChanged: (_) => setState(() {}))),
        ]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'pages.form.contacts'.tr(), children: [
          HBFormField(label: 'pages.form.website'.tr(), child: HBInput(controller: _website, enabled: !_saving, keyboardType: TextInputType.url)),
          HBFormField(label: 'pages.form.phone'.tr(), child: HBInput(controller: _phone, enabled: !_saving, keyboardType: TextInputType.phone)),
          HBFormField(label: 'pages.form.email'.tr(), child: HBInput(controller: _email, enabled: !_saving, keyboardType: TextInputType.emailAddress)),
          HBFormField(label: 'pages.form.address'.tr(), child: HBInput(controller: _address, enabled: !_saving, maxLength: 200)),
          HBFormField(label: 'pages.form.region'.tr(), child: PageRegionPicker(regions: regions.value ?? const [], selected: _region, enabled: !_saving, onSelected: (value) => setState(() => _region = value))),
        ]),
        if (_saving || _errorKey != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _publishing, errorKey: _saving ? null : _errorKey)],
        HBFormActions(primaryLabel: 'pages.form.create_action'.tr(), onPrimary: _valid && !_saving ? _create : null, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: _saving),
      ])))),
    ]))]));
  }
}

class PageRegionPicker extends StatelessWidget {
  final List<ReferenceRegion> regions;
  final ReferenceRegion? selected;
  final bool enabled;
  final ValueChanged<ReferenceRegion?> onSelected;

  const PageRegionPicker({super.key, required this.regions, required this.selected, required this.enabled, required this.onSelected});
  @override
  Widget build(BuildContext context) => HBSelect<ReferenceRegion>(value: selected, placeholder: 'pages.form.region_none'.tr(), allowClear: true, options: [for (final region in regions) HBSelectOption(value: region, label: region.name)], onChanged: enabled ? onSelected : null);
}

class PageImagesFormRow extends StatelessWidget {
  final PreparedUpload? avatar;
  final PreparedUpload? cover;
  final bool enabled;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickCover;
  final VoidCallback onRemoveAvatar;
  final VoidCallback onRemoveCover;

  const PageImagesFormRow({super.key, required this.avatar, required this.cover, required this.enabled, required this.onPickAvatar, required this.onPickCover, required this.onRemoveAvatar, required this.onRemoveCover});
  @override
  Widget build(BuildContext context) {
    final avatarField = HBFormField(label: 'pages.form.avatar'.tr(), child: HBImageField(kind: HBImageFieldKind.avatar, imageBytes: avatar?.bytes, onPick: enabled ? onPickAvatar : null, onRemove: avatar != null ? onRemoveAvatar : null, changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr()));
    final coverField = HBFormField(label: 'pages.form.cover'.tr(), child: HBImageField(kind: HBImageFieldKind.cover, imageBytes: cover?.bytes, onPick: enabled ? onPickCover : null, onRemove: cover != null ? onRemoveCover : null, changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr()));
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth < 560 ? Column(children: [avatarField, const SizedBox(height: AppSpacing.lg), coverField]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatarField), const SizedBox(width: AppSpacing.lg), Expanded(child: coverField)]));
  }
}