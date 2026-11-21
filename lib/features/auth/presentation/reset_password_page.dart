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
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  AppException? _error;
  bool _loading = false;

  @override
  void dispose() { _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_password.text.length < 8 || _password.text != _confirm.text) { setState(() => _error = const AppException('auth.password_reset.invalid_password')); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('auth.password_reset.success'.tr()))); context.go(AppRoutes.home); }
    } on AppException catch (error) { if (mounted) setState(() => _error = error); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) return Scaffold(body: HBEmptyState(icon: Icons.link_off_rounded, title: 'auth.password_reset.invalid_link_title'.tr(), message: 'auth.password_reset.invalid_link_message'.tr(), action: HBButton.primary(label: 'login.login_button'.tr(), onPressed: () => context.go(AppRoutes.login))));
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: HBCard(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('auth.password_reset.title'.tr(), style: context.textStyles.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                HBInput(controller: _password, label: 'auth.password_reset.new_password'.tr(), obscureText: true),
                const SizedBox(height: AppSpacing.md),
                HBInput(controller: _confirm, label: 'auth.password_reset.confirm_password'.tr(), obscureText: true),
                if (_error != null) ...[const SizedBox(height: AppSpacing.sm), Text(_error!.messageKey.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
                const SizedBox(height: AppSpacing.lg),
                HBButton.primary(label: 'auth.password_reset.save'.tr(), onPressed: _save, isLoading: _loading),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}