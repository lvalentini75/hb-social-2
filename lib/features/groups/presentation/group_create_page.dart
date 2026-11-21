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
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

class GroupCreatePage extends ConsumerStatefulWidget {
  const GroupCreatePage({super.key});

  @override
  ConsumerState<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _visibility = 'public';
  String _joinPolicy = 'open';
  String? _category;
  ReferenceRegion? _region;
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  bool _saving = false;
  bool _publishing = false;
  double _progress = 0;
  String? _errorKey;

  bool get _validName => _name.text.trim().length >= 3 && _name.text.trim().length <= 80;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(bool avatar) async {
    try {
      final service = ref.read(mediaUploadServiceProvider);
      final source = await MediaSourcePicker.imageBytes(context, service);
      if (source == null || !mounted) return;
      final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: avatar ? 1 : 3, outputWidth: avatar ? 512 : 1800, outputHeight: avatar ? 512 : 600, circularMask: avatar);
      if (cropped != null && mounted) setState(() => avatar ? _avatar = service.prepareJpeg(cropped) : _cover = service.prepareJpeg(cropped));
    } on AppException catch (error) {
      if (mounted) setState(() => _errorKey = error.messageKey);
    }
  }

  Future<UploadedMedia?> _upload(PreparedUpload? source, String userId, int index, int count) async {
    if (source == null) return null;
    final progress = UploadProgress();
    final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (index + value) / count); });
    try {
      return await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'group-media', userId: userId, upload: source, isPublic: true, progress: progress);
    } finally {
      await subscription.cancel();
      await progress.close();
    }
  }

  Future<void> _create() async {
    if (!_validName || _saving) return;
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) { context.go(AppRoutes.login); return; }
    setState(() { _saving = true; _publishing = false; _progress = 0; _errorKey = null; });
    UploadedMedia? avatar;
    UploadedMedia? cover;
    final uploads = [_avatar, _cover].whereType<PreparedUpload>().length;
    var index = 0;
    try {
      avatar = await _upload(_avatar, profile.id, index, uploads);
      if (_avatar != null) index++;
      cover = await _upload(_cover, profile.id, index, uploads);
      if (mounted) setState(() { _progress = uploads == 0 ? 0 : 1; _publishing = true; });
      final result = await ref.read(groupRepositoryProvider).createGroup(name: _name.text, description: _description.text, visibility: _visibility, joinPolicy: _joinPolicy, category: _category, regionId: _region?.id, avatarUrl: avatar?.path, coverUrl: cover?.path);
      ref.invalidate(groupsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('groups.created'.tr())));
      context.go(AppRoutes.groupDetailPath(result.slug));
    } on AppException catch (error) {
      if (avatar != null) await ref.read(mediaUploadServiceProvider).delete('group-media', avatar.path);
      if (cover != null) await ref.read(mediaUploadServiceProvider).delete('group-media', cover.path);
      if (mounted) setState(() { _saving = false; _publishing = false; _errorKey = error.messageKey; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    if (profile == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'groups.sign_in_title'.tr(), message: 'groups.sign_in_message'.tr(), action: HBButton.primary(label: 'groups.sign_in_cta'.tr(), onPressed: () => context.go(AppRoutes.login)))));
    final categories = ref.watch(groupCategoriesProvider);
    final regions = ref.watch(regionsProvider(profile.countryCode));
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final sourceCategories = categories.value ?? const <GroupCategory>[];
    final categoryItems = [...sourceCategories.where((item) => item.slug != 'altro'), ...sourceCategories.where((item) => item.slug == 'altro')];
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      sliver: SliverList.list(children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('group_form.new_title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('group_form.new_subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))]))),
        const SizedBox(height: AppSpacing.lg),
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HBFormSection(title: 'group_form.identity'.tr(), children: [
            GroupImagesFormRow(avatar: _avatar, cover: _cover, enabled: !_saving, onPickAvatar: () => _pick(true), onPickCover: () => _pick(false), onRemoveAvatar: () => setState(() => _avatar = null), onRemoveCover: () => setState(() => _cover = null)),
            HBFormField(label: 'groups.form.name'.tr(), required: true, helper: '${_name.text.length}/80', child: HBInput(controller: _name, hint: 'groups.form.name_hint'.tr(), maxLength: 80, enabled: !_saving, onChanged: (_) => setState(() {}))),
            HBFormField(label: 'groups.form.description'.tr(), helper: '${_description.text.length}/2000', child: HBInput(controller: _description, hint: 'groups.form.description_hint'.tr(), maxLength: 2000, minLines: 3, maxLines: 8, enabled: !_saving, onChanged: (_) => setState(() {}))),
          ]),
          const HBFormSectionDivider(),
          HBFormSection(title: 'group_form.access'.tr(), children: [
            HBFormField(label: 'groups.form.visibility'.tr(), child: HBChoice<String>(options: const ['public', 'private', 'secret'], value: _visibility, labelBuilder: (value) => 'groups.visibility.$value'.tr(), descriptions: {for (final value in const ['public', 'private', 'secret']) value: 'groups.visibility.${value}_help'.tr()}, onChanged: (value) => setState(() => _visibility = value))),
            HBFormField(label: 'groups.form.join_policy'.tr(), child: HBChoice<String>(options: const ['open', 'approval'], value: _joinPolicy, labelBuilder: (value) => 'groups.join_policy.$value'.tr(), descriptions: {'open': 'group_form.open_help'.tr(), 'approval': 'group_form.approval_help'.tr()}, onChanged: (value) => setState(() => _joinPolicy = value))),
          ]),
          const HBFormSectionDivider(),
          HBFormSection(title: 'group_form.classification'.tr(), children: [
            HBFormField(label: 'groups.form.category'.tr(), child: categories.isLoading ? const LinearProgressIndicator() : categories.hasError ? Text('groups.errors.categories'.tr()) : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: categoryItems.map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: _saving ? null : () => setState(() => _category = _category == item.slug ? null : item.slug))).toList())),
            HBFormField(label: 'groups.form.region'.tr(), child: GroupRegionPicker(regions: regions.value ?? const [], selected: _region, enabled: !_saving, onSelected: (value) => setState(() => _region = value))),
          ]),
          if (_saving || _errorKey != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _publishing, errorKey: _saving ? null : _errorKey)],
          HBFormActions(primaryLabel: 'group_form.create_action'.tr(), onPrimary: _validName && !_saving ? _create : null, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: _saving),
        ])))),
      ]),
    )]));
  }
}

class GroupRegionPicker extends StatelessWidget {
  final List<ReferenceRegion> regions;
  final ReferenceRegion? selected;
  final bool enabled;
  final ValueChanged<ReferenceRegion?> onSelected;

  const GroupRegionPicker({super.key, required this.regions, required this.selected, required this.enabled, required this.onSelected});

  @override
  Widget build(BuildContext context) => HBSelect<ReferenceRegion>(value: selected, placeholder: 'groups.form.region_none'.tr(), allowClear: true, options: [for (final region in regions) HBSelectOption(value: region, label: region.name)], onChanged: enabled ? onSelected : null);
}

class GroupImagesFormRow extends StatelessWidget {
  final PreparedUpload? avatar;
  final PreparedUpload? cover;
  final bool enabled;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickCover;
  final VoidCallback? onRemoveAvatar;
  final VoidCallback? onRemoveCover;
  final String? currentAvatarUrl;
  final String? currentCoverUrl;

  const GroupImagesFormRow({super.key, required this.avatar, required this.cover, required this.enabled, required this.onPickAvatar, required this.onPickCover, this.onRemoveAvatar, this.onRemoveCover, this.currentAvatarUrl, this.currentCoverUrl});

  @override
  Widget build(BuildContext context) {
    final avatarField = HBFormField(label: 'groups.form.avatar'.tr(), child: HBImageField(kind: HBImageFieldKind.avatar, imageUrl: currentAvatarUrl, imageBytes: avatar?.bytes, onPick: enabled ? onPickAvatar : null, onRemove: avatar != null ? onRemoveAvatar : null, changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr()));
    final coverField = HBFormField(label: 'groups.form.cover'.tr(), child: HBImageField(kind: HBImageFieldKind.cover, imageUrl: currentCoverUrl, imageBytes: cover?.bytes, onPick: enabled ? onPickCover : null, onRemove: cover != null ? onRemoveCover : null, changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr()));
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth < 560 ? Column(children: [avatarField, const SizedBox(height: 20), coverField]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatarField), const SizedBox(width: AppSpacing.lg), Expanded(child: coverField)]));
  }
}