import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/app_config.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/app_buttons.dart';
import 'package:hb_social/core/widgets/app_text_field.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hb_social/features/auth/providers/user_providers.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showTermsError = !_acceptedTerms);
    if (!_formKey.currentState!.validate() || !_acceptedTerms) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(currentUserProvider.notifier).signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
    } catch (e) {
      debugPrint('Signup failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AuthScaffold(
      title: 'signup.title'.tr(),
      subtitle: 'signup.subtitle'.tr(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'signup.name'.tr(),
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'validation.name_required'.tr();
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'signup.email'.tr(),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'validation.email_required'.tr();
                if (!value.contains('@') || !value.contains('.')) return 'validation.email_invalid'.tr();
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'signup.password'.tr(),
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'validation.password_required'.tr();
                if (value.length < AppConfig.minPasswordLength) return 'validation.password_too_short'.tr();
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () => setState(() {
                _acceptedTerms = !_acceptedTerms;
                if (_acceptedTerms) _showTermsError = false;
              }),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: LightModeColors.lightPrimary,
                    onChanged: (value) => setState(() {
                      _acceptedTerms = value ?? false;
                      if (_acceptedTerms) _showTermsError = false;
                    }),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Wrap(
                        children: [
                          Text('signup.terms_prefix'.tr(), style: context.textStyles.bodyMedium),
                          Text(
                            'signup.terms_link'.tr(),
                            style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightPrimary).semiBold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showTermsError)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Text('validation.terms_required'.tr(), style: context.textStyles.bodySmall?.withColor(colors.error)),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'signup.adults_only'.tr(),
              style: context.textStyles.bodySmall?.withColor(colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(label: 'signup.create_account_button'.tr(), onPressed: _submit, isLoading: _isSubmitting),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('${'signup.have_account'.tr()} ', style: context.textStyles.bodyMedium?.withColor(colors.onSurfaceVariant)),
                  AppTextLink(label: 'signup.login_link'.tr(), onPressed: () => context.pushReplacement(AppRoutes.login)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
