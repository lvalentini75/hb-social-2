import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_notice.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';

/// Account creation form. Like [LoginPage], it creates nothing: the primary
/// button only reveals the notice about Supabase (P03).
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showNotice = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'signup.title'.tr(),
      subtitle: 'signup.subtitle'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HBInput(
            label: 'signup.name'.tr(),
            hint: 'signup.name_hint'.tr(),
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
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
          const SizedBox(height: AppSpacing.lg),
          HBButton.primary(label: 'signup.create_account_button'.tr(), onPressed: () => setState(() => _showNotice = true)),
          if (_showNotice) ...[
            const SizedBox(height: AppSpacing.md),
            const AuthNotice(),
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
