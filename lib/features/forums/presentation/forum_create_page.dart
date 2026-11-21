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
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';

class ForumCreatePage extends ConsumerStatefulWidget {
  const ForumCreatePage({super.key});

  @override
  ConsumerState<ForumCreatePage> createState() => _ForumCreatePageState();
}

class _ForumCreatePageState extends ConsumerState<ForumCreatePage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _visibility = 'public';
  String? _category;
  String? _errorKey;
  bool _saving = false;
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  double _progress = 0;
  bool _publishing = false;

  bool get _valid => _name.text.trim().length >= 3 && _name.text.trim().length <= 80 && _description.text.trim().length <= 2000;

  @override
  void dispose() { _name.dispose(); _description.dispose(); super.dispose(); }

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
    try { return await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'forum-media', userId: userId, upload: source, isPublic: true, progress: progress); }
    finally { await subscription.cancel(); await progress.close(); }
  }

  Future<void> _create() async {
    if (!_valid || _saving) return;
    setState(() { _saving = true; _errorKey = null; });
    UploadedMedia? avatar;
    UploadedMedia? cover;
    try {
      final userId = ref.read(authSessionProvider).value!.user.id;
      final count = [_avatar, _cover].whereType<PreparedUpload>().length;
      avatar = await _upload(_avatar, userId, 0, count);
      cover = await _upload(_cover, userId, _avatar == null ? 0 : 1, count);
      if (mounted) setState(() => _publishing = true);
      final result = await ref.read(forumsRepositoryProvider).createForum(name: _name.text, description: _description.text, visibility: _visibility, category: _category, avatarUrl: avatar?.publicUrl, coverUrl: cover?.publicUrl);
      ref.invalidate(forumsProvider);
      if (mounted) context.go(AppRoutes.forumDetailPath(result.slug));
    } on AppException catch (error) {
      if (avatar != null) { try { await ref.read(mediaUploadServiceProvider).delete('forum-media', avatar.path); } catch (_) {} }
      if (cover != null) { try { await ref.read(mediaUploadServiceProvider).delete('forum-media', cover.path); } catch (_) {} }
      if (mounted) setState(() => _errorKey = error.messageKey);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authSessionProvider).value == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'forums.sign_in_title'.tr(), message: 'forums.sign_in_message'.tr(), action: HBFormActions(primaryLabel: 'forums.sign_in_cta'.tr(), onPrimary: () => context.go(AppRoutes.login)))));
    final categories = ref.watch(forumCategoriesProvider);
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Text('forums.form.new_title'.tr(), style: context.textStyles.headlineSmall))),
      const SizedBox(height: AppSpacing.lg),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBFormSection(title: 'forums.form.identity'.tr(), children: [
          LayoutBuilder(builder: (context, constraints) { final avatar = HBFormField(label: 'media_crop.avatar'.tr(), child: HBImageField(kind: HBImageFieldKind.avatar, imageBytes: _avatar?.bytes, onPick: _saving ? null : () => _pick(true), onRemove: _avatar == null ? null : () => setState(() => _avatar = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr())); final cover = HBFormField(label: 'media_crop.cover'.tr(), child: HBImageField(kind: HBImageFieldKind.cover, imageBytes: _cover?.bytes, onPick: _saving ? null : () => _pick(false), onRemove: _cover == null ? null : () => setState(() => _cover = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr())); return constraints.maxWidth < 560 ? Column(children: [avatar, const SizedBox(height: AppSpacing.md), cover]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatar), const SizedBox(width: AppSpacing.lg), Expanded(child: cover)]); }),
          HBFormField(label: 'forums.form.name'.tr(), required: true, helper: '${_name.text.length}/80', child: HBInput(controller: _name, maxLength: 80, hint: 'forums.form.name_hint'.tr(), enabled: !_saving, onChanged: (_) => setState(() {}))),
          HBFormField(label: 'forums.form.description'.tr(), helper: '${_description.text.length}/2000', child: HBInput(controller: _description, maxLength: 2000, minLines: 3, maxLines: 8, hint: 'forums.form.description_hint'.tr(), enabled: !_saving, onChanged: (_) => setState(() {}))),
        ]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'forums.form.access'.tr(), children: [HBFormField(label: 'forums.form.visibility'.tr(), child: HBChoice<String>(options: const ['public', 'private'], value: _visibility, labelBuilder: (value) => 'forums.visibility.$value'.tr(), descriptions: {'public': 'forums.visibility.public_help'.tr(), 'private': 'forums.visibility.private_help'.tr()}, onChanged: (value) => setState(() => _visibility = value)))]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'forums.form.classification'.tr(), children: [HBFormField(label: 'forums.form.category'.tr(), child: categories.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('forums.errors.categories'.tr()), data: (items) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: items.map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: _saving ? null : () => setState(() => _category = _category == item.slug ? null : item.slug))).toList()))) ]),
        if (_saving && (_avatar != null || _cover != null) || _errorKey != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _publishing, errorKey: _saving ? null : _errorKey)],
        HBFormActions(primaryLabel: 'forums.form.create_action'.tr(), onPrimary: _valid && !_saving ? _create : null, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: _saving),
      ])))),
    ]))]));
  }
}