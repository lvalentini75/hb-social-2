import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/l10n/app_locales.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_country_picker.dart';
import 'package:hb_social/core/i18n/locale_resolver.dart';
import 'package:hb_social/features/auth/data/supabase_auth_repository.dart';
import 'package:hb_social/features/auth/domain/social_auth_models.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/features/legal/providers/legal_providers.dart';

class CompleteProfilePage extends ConsumerWidget {
  const CompleteProfilePage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(authProfileStateProvider).when(
    loading: () => const AuthScaffold(title: '', subtitle: '', child: Center(child: CircularProgressIndicator())),
    error: (_, __) => AuthScaffold(title: 'auth.complete_profile.title'.tr(), subtitle: 'auth.complete_profile.subtitle'.tr(), child: Text('auth.generic'.tr())),
    data: (state) => state == null ? const SizedBox.shrink() : CompleteProfileForm(authState: state),
  );
}

class CompleteProfileForm extends ConsumerStatefulWidget {
  final SocialAuthState authState;
  const CompleteProfileForm({super.key, required this.authState});
  @override ConsumerState<CompleteProfileForm> createState() => _CompleteProfileFormState();
}

class _CompleteProfileFormState extends ConsumerState<CompleteProfileForm> {
  late final name = TextEditingController(text: widget.authState.displayName?.isNotEmpty == true ? widget.authState.displayName : SupabaseAuthRepository.appleDisplayName ?? '');
  late final username = TextEditingController(text: widget.authState.username?.isNotEmpty == true ? widget.authState.username : _suggestUsername(name.text));
  final birthDateText = TextEditingController();
  final email = TextEditingController();
  Timer? debounce;
  DateTime? birthDate;
  String? countryCode;
  String? regionId;
  late String locale = AppLocales.supported.any((item) => item.languageCode == widget.authState.locale) ? widget.authState.locale : LocaleResolver.fromDevice().locale.languageCode;
  bool languageTouched = false;
  UsernameAvailability? availability;
  PreparedUpload? chosenAvatar;
  bool useProviderAvatar = false;
  bool saving = false;
  String? errorKey;
  bool legalAccepted = false;
  bool profileSaved = false;
  String? savedLocale;

  @override void initState() { super.initState(); countryCode = widget.authState.countryCode; regionId = widget.authState.homeRegionId; username.addListener(_scheduleUsernameCheck); WidgetsBinding.instance.addPostFrameCallback((_) => _checkUsername()); }
  @override void dispose() { debounce?.cancel(); username.removeListener(_scheduleUsernameCheck); name.dispose(); username.dispose(); birthDateText.dispose(); email.dispose(); super.dispose(); }

  void _scheduleUsernameCheck() { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 400), _checkUsername); }
  Future<void> _checkUsername() async {
    final value = username.text.trim().toLowerCase();
    if (value.length < 3) { if (mounted) setState(() => availability = UsernameAvailability(username: value, available: false, reason: 'invalid')); return; }
    try { final result = await ref.read(authRepositoryProvider).usernameAvailable(value); if (mounted && username.text.trim().toLowerCase() == result.username) setState(() => availability = result); } catch (_) {}
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(context: context, initialDate: birthDate ?? DateTime(now.year - widget.authState.minAge, now.month, now.day), firstDate: DateTime(1900), lastDate: now, locale: context.locale);
    if (value != null && mounted) setState(() { birthDate = value; birthDateText.text = DateFormat.yMd(context.locale.toString()).format(value); });
  }

  Future<void> _pickAvatar() async {
    try {
      final service = ref.read(mediaUploadServiceProvider);
      final source = await MediaSourcePicker.imageBytes(context, service);
      if (source == null || !mounted) return;
      final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: 1, outputWidth: 512, outputHeight: 512, circularMask: true);
      if (cropped != null && mounted) setState(() { chosenAvatar = service.prepareJpeg(cropped); useProviderAvatar = false; });
    } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); }
  }

  Future<String?> _avatarUrl() async {
    final source = chosenAvatar ?? await _providerAvatarUpload();
    if (source == null) return null;
    final uploaded = await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'avatars', userId: widget.authState.userId, upload: source, isPublic: true);
    return uploaded.publicUrl;
  }

  Future<PreparedUpload?> _providerAvatarUpload() async {
    if (!useProviderAvatar || widget.authState.avatarUrl == null) return null;
    try {
      final response = await Dio().get<List<int>>(widget.authState.avatarUrl!, options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data ?? const []);
      return bytes.isEmpty ? null : ref.read(mediaUploadServiceProvider).prepareJpeg(bytes);
    } catch (_) { return null; }
  }

  Future<void> _submit() async {
    final birthDateRequired = !widget.authState.ageConfirmed && !profileSaved;
    if (birthDateRequired && birthDate == null || countryCode == null || name.text.trim().isEmpty || availability?.available != true || !legalAccepted) { setState(() => errorKey = 'auth.complete_profile.errors.required'); return; }
    setState(() { saving = true; errorKey = null; });
    try {
      if (!profileSaved) {
        final result = await ref.read(authRepositoryProvider).completeProfile(birthDate: birthDate, countryCode: countryCode, username: username.text, displayName: name.text, locale: locale, regionId: regionId, avatarUrl: await _avatarUrl());
        profileSaved = true;
        savedLocale = result.locale;
      }
      await ref.read(legalRepositoryProvider).acceptCurrent('terms', locale);
      await ref.read(legalRepositoryProvider).acceptCurrent('privacy', locale);
      if (widget.authState.email == null && email.text.trim().isNotEmpty) await ref.read(authRepositoryProvider).updateEmail(email.text);
      ref.invalidate(authProfileStateProvider); ref.invalidate(currentProfileProvider); ref.invalidate(privateUserSettingsProvider);
      if (!mounted) return;
      await context.setLocale(Locale(savedLocale ?? locale));
      if (widget.authState.email == null && email.text.trim().isNotEmpty && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('auth.complete_profile.email_confirmation'.tr())));
      if (mounted) context.go(AppRoutes.home);
    } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey == 'sensitive.content_blocked' ? 'auth.complete_profile.errors.content_blocked' : error.messageKey); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    final selectedCountry = countries.value?.where((item) => item.code == countryCode).firstOrNull;
    final regions = selectedCountry?.hasRegions == true ? ref.watch(regionsProvider(countryCode!)) : null;
    final usernameError = availability == null || availability!.available ? null : 'auth.complete_profile.username_${availability!.reason ?? 'invalid'}'.tr();
    return AuthScaffold(title: 'auth.complete_profile.title'.tr(), subtitle: 'auth.complete_profile.subtitle'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.authState.avatarUrl != null || chosenAvatar != null) HBFormField(label: 'auth.complete_profile.photo'.tr(), child: Column(children: [CircleAvatar(radius: 44, backgroundImage: chosenAvatar != null ? MemoryImage(chosenAvatar!.bytes) : NetworkImage(widget.authState.avatarUrl!) as ImageProvider), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, children: [if (widget.authState.avatarUrl != null) HBButton.soft(label: 'auth.complete_profile.use_photo'.tr(), onPressed: () => setState(() { useProviderAvatar = true; chosenAvatar = null; })), HBButton.secondary(label: 'auth.complete_profile.choose_photo'.tr(), onPressed: _pickAvatar)])])),
      HBInput(label: 'auth.complete_profile.display_name'.tr(), controller: name, maxLength: 80), const SizedBox(height: AppSpacing.md),
      HBInput(label: 'auth.complete_profile.username'.tr(), controller: username, maxLength: 30, errorText: usernameError, suffixIcon: availability?.available == true ? const Icon(Icons.check_circle, color: LightModeColors.success) : null, inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-z0-9_]'))]),
      Text('auth.complete_profile.username_help'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.textTertiary)), const SizedBox(height: AppSpacing.md),
      countries.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('errors.network'.tr()), data: (_) => HBFormField(label: 'auth.complete_profile.country'.tr(), child: HBCountryPicker(value: countryCode, onChanged: (country) => setState(() { countryCode = country.code; regionId = null; final deviceSupported = WidgetsBinding.instance.platformDispatcher.locales.any((item) => LocaleResolver.supportedLanguageCodes.contains(item.languageCode)); if (!languageTouched && !deviceSupported) locale = country.defaultLocale; })))), const SizedBox(height: AppSpacing.md),
      if (regions != null) regions.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('errors.network'.tr()), data: (items) => HBFormField(label: 'auth.complete_profile.region'.tr(), child: HBSelect<String>(value: regionId, allowClear: true, options: [for (final item in items) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => regionId = value)))),
      const SizedBox(height: AppSpacing.md), HBFormField(label: 'auth.complete_profile.language'.tr(), child: HBSelect<String>(value: locale, options: [for (final item in AppLocales.supported) HBSelectOption(value: item.languageCode, label: 'settings.language.names.${item.languageCode}'.tr())], onChanged: (value) => setState(() { locale = value ?? locale; languageTouched = true; }))),
      if (!widget.authState.ageConfirmed) ...[const SizedBox(height: AppSpacing.md), GestureDetector(onTap: _pickBirthDate, child: AbsorbPointer(child: HBInput(label: 'auth.complete_profile.birth_date'.tr(), hint: 'auth.complete_profile.age_help'.tr(namedArgs: {'min_age': '${widget.authState.minAge}'}), controller: birthDateText, enabled: false)))],
      if (widget.authState.email == null) ...[const SizedBox(height: AppSpacing.md), HBInput(label: 'auth.complete_profile.notification_email'.tr(), controller: email, keyboardType: TextInputType.emailAddress)],
      CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: legalAccepted, onChanged: (value) => setState(() => legalAccepted = value == true), title: Wrap(children: [Text('legal.signup.prefix'.tr()), TextButton(onPressed: () => context.push('/legal/terms'), child: Text('legal.kind.terms'.tr())), Text('legal.signup.middle'.tr()), TextButton(onPressed: () => context.push('/legal/privacy'), child: Text('legal.kind.privacy'.tr()))])),
      if (errorKey != null) ...[const SizedBox(height: AppSpacing.sm), Text(errorKey!.tr(namedArgs: {'min_age': '${widget.authState.minAge}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
      const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'common.continue'.tr(), onPressed: saving ? null : _submit, isLoading: saving), const SizedBox(height: AppSpacing.sm), HBButton.ghost(label: 'auth.logout'.tr(), onPressed: saving ? null : () async { await ref.read(authRepositoryProvider).signOut(); if (mounted) context.go(AppRoutes.login); }),
    ]));
  }

  static String _suggestUsername(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.length >= 3 ? normalized.substring(0, normalized.length.clamp(0, 30)) : '';
  }
}