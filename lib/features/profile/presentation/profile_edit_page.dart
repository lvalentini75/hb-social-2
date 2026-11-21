import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

class ProfileEditPage extends ConsumerWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authSessionProvider).value == null) return ProfileAuthRequired(onSignIn: () => context.go(AppRoutes.login));
    return ref.watch(currentProfileProvider).when(
      loading: () => const PageColumns(center: Center(child: CircularProgressIndicator())),
      error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'profile.error_title'.tr(), message: 'profile.error_message'.tr()))),
      data: (profile) => profile == null ? ProfileAuthRequired(onSignIn: () => context.go(AppRoutes.login)) : ProfileEditForm(profile: profile),
    );
  }
}

class ProfileAuthRequired extends StatelessWidget {
  final VoidCallback onSignIn;
  const ProfileAuthRequired({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.lock_outline, title: 'profile.auth_required_title'.tr(), message: 'profile.auth_required_message'.tr(), action: HBButton.primary(label: 'profile.signed_out_cta'.tr(), onPressed: onSignIn))));
}

class ProfileEditForm extends ConsumerStatefulWidget {
  final UserProfile profile;
  const ProfileEditForm({super.key, required this.profile});

  @override
  ConsumerState<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  late final TextEditingController _username = TextEditingController(text: widget.profile.username);
  late final TextEditingController _name = TextEditingController(text: widget.profile.displayName);
  late final TextEditingController _bio = TextEditingController(text: widget.profile.bio ?? '');
  final TextEditingController _municipality = TextEditingController();
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  String? _regionId;
  String? _municipalityId;
  String? _unitId;
  String? _errorKey;
  double _avatarProgress = 0;
  double _coverProgress = 0;
  int _activeUpload = 0;
  bool _publishing = false;
  bool _uploadAttempted = false;
  bool _contentBlocked = false;

  @override
  void initState() {
    super.initState();
    _regionId = widget.profile.homeRegionId;
    _municipalityId = widget.profile.homeMunicipalityId;
    _unitId = widget.profile.huntingUnitId;
  }

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _bio.dispose();
    _municipality.dispose();
    super.dispose();
  }

  Future<void> _pick(bool cover) async {
    try {
      final service = ref.read(mediaUploadServiceProvider);
      final source = await MediaSourcePicker.imageBytes(context, service);
      if (source == null || !mounted) return;
      final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: cover ? 3 : 1, outputWidth: cover ? 1800 : 512, outputHeight: cover ? 600 : 512, circularMask: !cover);
      if (cropped != null && mounted) setState(() => cover ? _cover = service.prepareJpeg(cropped) : _avatar = service.prepareJpeg(cropped));
    } on AppException catch (error) {
      if (mounted) setState(() => _errorKey = error.messageKey);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _errorKey = 'profile.edit.name_required');
      return;
    }
    final avatarProgress = UploadProgress();
    final coverProgress = UploadProgress();
    final subscriptions = <StreamSubscription<double>>[
      avatarProgress.stream.listen((value) { if (mounted) setState(() => _avatarProgress = value); }),
      coverProgress.stream.listen((value) { if (mounted) setState(() => _coverProgress = value); }),
    ];
    setState(() { _errorKey = null; _contentBlocked = false; _avatarProgress = 0; _coverProgress = 0; _activeUpload = 0; _publishing = false; _uploadAttempted = _avatar != null || _cover != null; });
    try {
      await ref.read(profileSaveProvider.notifier).save(current: widget.profile, username: _username.text, displayName: _name.text, bio: _bio.text, regionId: _regionId, municipalityId: _municipalityId, huntingUnitId: _unitId, avatar: _avatar, cover: _cover, avatarProgress: avatarProgress, coverProgress: coverProgress, onUploadIndex: (index) { if (mounted) setState(() => _activeUpload = index); }, onPublishing: () { if (mounted) setState(() => _publishing = true); });
      if (mounted) context.go(AppRoutes.profile);
    } on AppException catch (error) {
      if (mounted) setState(() { _errorKey = error.messageKey; _contentBlocked = error.messageKey == 'sensitive.content_blocked'; });
    } finally {
      for (final subscription in subscriptions) { await subscription.cancel(); }
      await avatarProgress.close();
      await coverProgress.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileSaveProvider).isLoading;
    final uploadCount = (_avatar == null ? 0 : 1) + (_cover == null ? 0 : 1);
    final overallProgress = uploadCount == 0 ? 0.0 : (_avatarProgress + _coverProgress) / uploadCount;
    final regions = ref.watch(regionsProvider(widget.profile.countryCode));
    final units = _regionId == null ? null : ref.watch(huntingUnitsByRegionProvider(_regionId!));
    final municipality = _municipalityId == null ? null : ref.watch(municipalityProvider(_municipalityId!));
    municipality?.whenData((value) { if (value != null && _municipality.text.isEmpty) _municipality.text = value.compactName; });
    return PageColumns(
      center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
        Text('profile.edit.title'.tr(), style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 700 ? AppSpacing.lg : AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(builder: (context, constraints) {
            final avatar = HBImageField(kind: HBImageFieldKind.avatar, imageUrl: widget.profile.avatarUrl, imageBytes: _avatar?.bytes, onPick: saving ? null : () => _pick(false), onRemove: _avatar == null ? null : () => setState(() => _avatar = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr());
            final cover = HBImageField(kind: HBImageFieldKind.cover, imageUrl: widget.profile.coverUrl, imageBytes: _cover?.bytes, onPick: saving ? null : () => _pick(true), onRemove: _cover == null ? null : () => setState(() => _cover = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr());
            return constraints.maxWidth < 560 ? Column(children: [avatar, const SizedBox(height: AppSpacing.md), cover]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatar), const SizedBox(width: AppSpacing.lg), Expanded(child: cover)]);
          }),
          const SizedBox(height: AppSpacing.lg),
          HBInput(label: 'profile.edit.display_name'.tr(), controller: _name, maxLength: 80, enabled: !saving, errorText: _contentBlocked ? 'verification.errors.content_blocked'.tr() : null),
          const SizedBox(height: AppSpacing.md),
          HBInput(label: 'profile.edit.username'.tr(), hint: 'profile.edit.username_hint'.tr(), controller: _username, maxLength: 30, enabled: !saving, errorText: _contentBlocked ? 'verification.errors.content_blocked'.tr() : null, inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]'))]),
          const SizedBox(height: AppSpacing.md),
          HBInput(label: 'profile.edit.bio'.tr(), controller: _bio, maxLength: 300, maxLines: 4, enabled: !saving, errorText: _contentBlocked ? 'verification.errors.content_blocked'.tr() : null),
          const SizedBox(height: AppSpacing.md),
          HBFormField(label: 'profile.edit.region'.tr(), child: regions.when(loading: () => Text('common.loading'.tr()), error: (_, __) => Text('settings.reference_error'.tr()), data: (items) => HBSelect<String>(value: items.any((item) => item.id == _regionId) ? _regionId : null, options: [for (final item in items) HBSelectOption(value: item.id, label: item.name)], onChanged: saving ? null : (value) => setState(() { _regionId = value; _unitId = null; })))),
          if (widget.profile.countryCode == 'IT') ...[const SizedBox(height: AppSpacing.md), HBFormField(label: 'settings.municipality'.tr(), child: Column(children: [HBPlaceField<Municipality>(controller: _municipality, enabled: !saving, hint: 'settings.municipality_hint'.tr(), search: (query) async => [for (final item in await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: 'IT')) HBPlaceSuggestion(value: item, title: item.compactName, subtitle: [if (item.nameAlt?.isNotEmpty == true) item.nameAlt!, item.regionName].join(' · '))], onSelected: (item) => setState(() { _municipalityId = item.id; _regionId = item.regionId; _unitId = null; })), if (_municipalityId != null) Align(alignment: Alignment.centerRight, child: HBButton.ghost(label: 'common.remove'.tr(), onPressed: () => setState(() { _municipalityId = null; _municipality.clear(); }), size: HBButtonSize.sm))]))],
          if (_regionId != null) ...[const SizedBox(height: AppSpacing.md), HBFormField(label: 'settings.hunting_unit'.tr(), child: HBSelect<String>(value: _unitId, allowClear: true, options: [for (final item in units?.value ?? const []) HBSelectOption(value: item.id, label: item.name, groupLabel: 'hunting.unit_type.${item.unitType}'.tr())], onChanged: saving ? null : (value) => setState(() => _unitId = value)))],
          if (_uploadAttempted && (saving || _errorKey != null)) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: overallProgress, publishing: _publishing, fileIndex: _activeUpload == 0 ? null : _activeUpload, fileCount: uploadCount, errorKey: saving ? null : _errorKey)] else if (_errorKey != null) ...[const SizedBox(height: AppSpacing.sm), Text(_errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
          const SizedBox(height: AppSpacing.lg),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.secondary(label: 'common.back'.tr(), onPressed: saving ? null : () => context.pop()), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: saving ? 'profile.edit.saving'.tr() : 'profile.edit.save'.tr(), onPressed: saving ? null : _save)]),
        ])))),
      ]))]),
    );
  }
}