import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/albums/domain/album.dart';
import 'package:hb_social/features/albums/providers/album_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class AlbumFormPage extends ConsumerStatefulWidget {
  final String? albumId;
  const AlbumFormPage({super.key, this.albumId});
  @override
  ConsumerState<AlbumFormPage> createState() => _AlbumFormPageState();
}

class _AlbumFormPageState extends ConsumerState<AlbumFormPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  AlbumVisibility _visibility = AlbumVisibility.public;
  bool _loaded = false;
  bool _saving = false;
  String? _errorKey;
  bool get _editing => widget.albumId != null;

  @override
  void dispose() { _title.dispose(); _description.dispose(); super.dispose(); }

  void _load(Album album) { if (_loaded) return; _loaded = true; _title.text = album.title; _description.text = album.description ?? ''; _visibility = album.visibility; }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty || title.length > 80) { setState(() => _errorKey = 'albums.errors.album_title_invalid'); return; }
    setState(() { _saving = true; _errorKey = null; });
    try {
      final repository = ref.read(albumsRepositoryProvider);
      String id;
      if (_editing) { id = widget.albumId!; await repository.updateAlbum(id, title: title, description: _description.text.trim().isEmpty ? null : _description.text.trim(), visibility: _visibility); }
      else { id = await repository.createAlbum(title: title, description: _description.text.trim().isEmpty ? null : _description.text.trim(), visibility: _visibility); }
      ref.invalidate(albumProvider(id));
      final userId = ref.read(authSessionProvider).value?.user.id;
      if (userId != null) ref.invalidate(albumsByOwnerProvider(userId));
      if (mounted) context.go('${AppRoutes.albumDetailPath(id)}${_editing ? '' : '?upload=1'}');
    } on AppException catch (error) { if (mounted) setState(() { _saving = false; _errorKey = error.messageKey; }); }
  }

  Future<void> _delete(Album album) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('albums.delete_title'.tr()), content: Text('albums.delete_message'.plural(album.itemCount)), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'albums.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    setState(() => _saving = true);
    try { await ref.read(albumsRepositoryProvider).deleteAlbum(album.id); ref.invalidate(albumsByOwnerProvider(album.ownerId)); if (mounted) context.go('${AppRoutes.profile}?tab=albums'); }
    on AppException catch (error) { if (mounted) setState(() { _saving = false; _errorKey = error.messageKey; }); }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'albums.sign_in_title'.tr(), message: 'albums.sign_in_message'.tr(), action: HBButton.primary(label: 'albums.sign_in'.tr(), onPressed: () => context.go(AppRoutes.login)))));
    final value = _editing ? ref.watch(albumProvider(widget.albumId!)) : null;
    if (value?.isLoading == true) return const PageColumns(center: Center(child: CircularProgressIndicator()));
    final album = value?.value;
    if (_editing && (value?.hasError == true || album == null || album.ownerId != session.user.id)) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.photo_library_outlined, title: 'albums.unavailable_title'.tr(), message: 'albums.unavailable_message'.tr())));
    if (album != null) _load(album);
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Text((_editing ? 'albums.edit_title' : 'albums.create_title').tr(), style: context.textStyles.headlineSmall))),
      const SizedBox(height: AppSpacing.lg),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBFormSection(title: 'albums.form_album'.tr(), children: [HBFormField(label: 'albums.title_label'.tr(), required: true, child: HBInput(controller: _title, maxLength: 80, enabled: !_saving)), HBFormField(label: 'albums.description_label'.tr(), child: HBInput(controller: _description, minLines: 3, maxLines: 7, maxLength: 1000, enabled: !_saving))]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'albums.visibility_title'.tr(), children: [HBChoice<AlbumVisibility>(options: AlbumVisibility.values, value: _visibility, onChanged: (value) => setState(() => _visibility = value), labelBuilder: (value) => 'albums.visibility.${value.name}'.tr(), descriptions: {for (final value in AlbumVisibility.values) value: 'albums.visibility_help.${value.name}'.tr()})]),
        if (_errorKey != null) ...[const SizedBox(height: AppSpacing.md), Text(_errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
        HBFormActions(primaryLabel: (_editing ? 'common.save' : 'albums.create').tr(), onPrimary: _save, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: _saving),
        if (_editing) ...[const SizedBox(height: AppSpacing.md), HBButton.ghost(label: 'albums.delete'.tr(), onPressed: _saving ? null : () => _delete(album!), foregroundColor: LightModeColors.lightError)],
      ])))),
    ]))]));
  }
}