import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_notice.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_social_buttons.dart';
import 'package:hb_social/core/providers/platform_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorKey;
  bool _resetSent = false;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorKey = 'auth.errors.required_fields');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorKey = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(email: _emailController.text, password: _passwordController.text);
      final needsMfa = await ref.read(authSecurityRepositoryProvider).needsChallenge();
      if (mounted) context.go(needsMfa ? AppRoutes.mfaChallenge : AppRoutes.home);
    } on AppException catch (error) {
      if (mounted) setState(() => _errorKey = error.messageKey);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) { setState(() => _errorKey = 'auth.errors.required_fields'); return; }
    setState(() { _isLoading = true; _errorKey = null; });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_emailController.text, '${Uri.base.origin}/#/reset-password');
      if (mounted) setState(() => _resetSent = true);
    } on AppException catch (error) {
      if (mounted) setState(() => _errorKey = error.messageKey);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authConfig = ref.watch(platformConfigProvider).value?.auth;
    final showEmail = authConfig?.emailPassword ?? true;
    return AuthScaffold(
      title: 'auth.social.title'.tr(),
      subtitle: 'auth.social.subtitle'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WelcomeSocialButtons(showDivider: false),
          if (showEmail) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Text('auth.social.or'.tr())), const Expanded(child: Divider())]),
          const SizedBox(height: AppSpacing.lg),
          HBInput(
            label: 'login.email'.tr(),
            hint: 'login.email_hint'.tr(),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          HBInput(
            label: 'login.password'.tr(),
            hint: 'login.password_hint'.tr(),
            controller: _passwordController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          Align(alignment: Alignment.centerRight, child: HBButton.ghost(label: 'login.forgot_password'.tr(), size: HBButtonSize.sm, onPressed: _forgotPassword)),
          const SizedBox(height: AppSpacing.lg),
          HBButton.primary(label: 'login.login_button'.tr(), onPressed: _submit, isLoading: _isLoading),
          if (_errorKey != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthNotice(messageKey: _errorKey!, isError: true),
          ],
          if (_resetSent) ...[const SizedBox(height: AppSpacing.md), const AuthNotice(messageKey: 'auth.password_reset.sent')],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: HBButton.ghost(
              label: 'login.signup_link'.tr(),
              size: HBButtonSize.sm,
              onPressed: () => context.go(AppRoutes.signup),
            ),
          ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('auth.social.legal_note'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary)),
        ],
      ),
    );
  }
}
