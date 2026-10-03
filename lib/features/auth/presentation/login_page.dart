import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/app_buttons.dart';
import 'package:hb_social/core/widgets/app_text_field.dart';
import 'package:hb_social/core/widgets/social_auth_buttons.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hb_social/features/auth/providers/user_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final success = ref.read(currentUserProvider.notifier).logIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (success) {
        final user = ref.read(currentUserProvider);
        if (user != null && user.onboardingCompleted) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.onboarding);
        }
      } else {
        setState(() => _errorText = 'login.error_invalid'.tr());
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      setState(() => _errorText = 'login.error_invalid'.tr());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AuthScaffold(
      title: 'login.title'.tr(),
      subtitle: 'login.subtitle'.tr(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'login.email'.tr(),
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
              label: 'login.password'.tr(),
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'validation.password_required'.tr();
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: AppTextLink(label: 'login.forgot_password'.tr(), onPressed: () {}),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_errorText!, style: context.textStyles.bodySmall?.withColor(colors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: 'login.login_button'.tr(), onPressed: _submit, isLoading: _isSubmitting),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: Divider(color: colors.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('welcome.or_continue_with'.tr(), style: context.textStyles.bodySmall?.withColor(colors.onSurfaceVariant)),
                ),
                Expanded(child: Divider(color: colors.outline)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SocialAuthButtons(),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text('${'login.no_account'.tr()} ', style: context.textStyles.bodyMedium?.withColor(colors.onSurfaceVariant)),
                  AppTextLink(label: 'login.signup_link'.tr(), onPressed: () => context.pushReplacement(AppRoutes.signup)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
