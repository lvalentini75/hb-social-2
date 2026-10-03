import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_notice.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_scaffold.dart';

/// Sign-in form. There is no authentication backend yet (see
/// `docs/DECISIONS.md`): the primary button only surfaces the notice telling
/// the user that sign-in activates with Supabase (P03). Nothing is stored,
/// no session is simulated and no navigation into the app happens here.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showNotice = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'login.title'.tr(),
      subtitle: 'login.subtitle'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: AppSpacing.lg),
          HBButton.primary(label: 'login.login_button'.tr(), onPressed: () => setState(() => _showNotice = true)),
          if (_showNotice) ...[
            const SizedBox(height: AppSpacing.md),
            const AuthNotice(),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: HBButton.ghost(
              label: 'login.signup_link'.tr(),
              size: HBButtonSize.sm,
              onPressed: () => context.go(AppRoutes.signup),
            ),
          ),
        ],
      ),
    );
  }
}
