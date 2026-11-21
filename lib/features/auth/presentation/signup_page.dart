import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_country_picker.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_notice.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_social_buttons.dart';
import 'package:hb_social/features/legal/providers/legal_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _isLoading = false;
  String? _errorKey;
  String? _countryCode;
  String? _usernameError;
  DateTime? _birthDate;
  Map<String, String> _errorArgs = const {};
  bool _legalAccepted = false;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(context: context, initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day), firstDate: DateTime(1900), lastDate: now, locale: context.locale);
    if (value != null && mounted) setState(() {
      _birthDate = value;
      _birthDateController.text = DateFormat.yMd(context.locale.toString()).format(value);
    });
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.length < 3) return;
    try {
      final available = await ref.read(profileRepositoryProvider).isUsernameAvailable(username);
      if (mounted) setState(() => _usernameError = available ? null : 'auth.errors.username_in_use');
    } on AppException catch (error) {
      if (mounted) setState(() => _usernameError = error.messageKey);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _usernameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.isEmpty || _countryCode == null || _birthDate == null || _usernameError != null || !_legalAccepted) {
      setState(() => _errorKey = 'auth.errors.required_fields');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorKey = null;
    });
    try {
      await _createAccount().timeout(const Duration(seconds: 15), onTimeout: () => throw const AppException('auth.errors.signup_timeout'));
      if (mounted) context.go(AppRoutes.onboarding);
    } catch (error) {
      final appError = ErrorMapper.fromSupabase(error);
      if (mounted) setState(() { _errorKey = appError.messageKey; _errorArgs = appError.namedArgs; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createAccount() async {
    final country = ref.read(countriesProvider).value?.where((item) => item.code == _countryCode).firstOrNull;
    if (country == null) throw const AppException('auth.errors.required_fields');
    final result = await ref.read(supabaseClientProvider).rpc('minimum_age_for', params: {'p_country': country.code});
    final minimumAge = (result as num?)?.toInt() ?? 18;
    if (!_isOldEnough(_birthDate!, minimumAge)) throw AppException('auth.age_below_minimum', namedArgs: {'n': '$minimumAge'});
    final locale = context.locale.languageCode;
    await ref.read(authRepositoryProvider).signUp(username: _usernameController.text, displayName: _nameController.text, email: _emailController.text, password: _passwordController.text, countryCode: country.code, locale: locale, birthDate: _birthDate!);
    if (ref.read(supabaseClientProvider).auth.currentSession == null) await ref.read(supabaseClientProvider).auth.onAuthStateChange.firstWhere((event) => event.session != null);
    await ref.read(legalRepositoryProvider).acceptCurrent('terms', locale);
    await ref.read(legalRepositoryProvider).acceptCurrent('privacy', locale);
  }

  bool _isOldEnough(DateTime birthDate, int years) {
    final now = DateTime.now();
    final threshold = DateTime(now.year - years, now.month, now.day);
    return !birthDate.isAfter(threshold);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    return AuthScaffold(
      title: 'signup.title'.tr(),
      subtitle: 'signup.subtitle'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WelcomeSocialButtons(showDivider: false),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Text('auth.social.or'.tr())), const Expanded(child: Divider())]),
          const SizedBox(height: AppSpacing.lg),
          HBInput(
            label: 'signup.name'.tr(),
            hint: 'signup.name_hint'.tr(),
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Focus(
            onFocusChange: (hasFocus) { if (!hasFocus) _checkUsername(); },
            child: HBInput(label: 'signup.username'.tr(), hint: 'signup.username_hint'.tr(), controller: _usernameController, errorText: _usernameError == null ? null : _usernameError!.tr(), onChanged: (_) => setState(() => _usernameError = null)),
          ),
          const SizedBox(height: AppSpacing.md),
          countries.when(
            data: (_) => HBFormField(label: 'signup.country'.tr(), child: HBCountryPicker(value: _countryCode, onChanged: (country) => setState(() => _countryCode = country.code))),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text('errors.network'.tr()),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: _pickBirthDate,
            child: AbsorbPointer(
              child: HBInput(label: 'signup.birth_date'.tr(), hint: 'signup.birth_date_hint'.tr(), controller: _birthDateController, enabled: false, prefixIcon: const Icon(Icons.cake_outlined, color: LightModeColors.lightOnSurfaceVariant)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HBInput(
            label: 'signup.email'.tr(),
            hint: 'login.email_hint'.tr(),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          HBInput(
            label: 'signup.password'.tr(),
            hint: 'login.password_hint'.tr(),
            controller: _passwordController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'signup.adults_only'.tr(),
            style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant),
          ),
          CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: _legalAccepted, onChanged: (value) => setState(() => _legalAccepted = value == true), title: Wrap(children: [Text('legal.signup.prefix'.tr()), TextButton(onPressed: () => context.push('/legal/terms'), child: Text('legal.kind.terms'.tr())), Text('legal.signup.middle'.tr()), TextButton(onPressed: () => context.push('/legal/privacy'), child: Text('legal.kind.privacy'.tr()))])),
          const SizedBox(height: AppSpacing.lg),
          HBButton.primary(label: 'signup.create_account_button'.tr(), onPressed: _submit, isLoading: _isLoading),
          if (_errorKey != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthNotice(messageKey: _errorKey!, namedArgs: _errorArgs, isError: true),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: HBButton.ghost(
              label: 'signup.login_link'.tr(),
              size: HBButtonSize.sm,
              onPressed: () => context.go(AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }
}
