import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});
  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  AppException? _error;
  bool _loading = false;

  @override
  void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    final email = ref.read(authSessionProvider).value?.user.email;
    if (email == null || _next.text.length < 8 || _next.text != _confirm.text) { setState(() => _error = const AppException('auth.password_reset.invalid_password')); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signIn(email: email, password: _current.text);
      await ref.read(authRepositoryProvider).updatePassword(_next.text);
      if (mounted) context.pop();
    } on AppException catch (error) { if (mounted) setState(() => _error = error); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('auth.password_change.title'.tr()), content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(controller: _current, label: 'auth.password_change.current'.tr(), obscureText: true), const SizedBox(height: AppSpacing.md), HBInput(controller: _next, label: 'auth.password_reset.new_password'.tr(), obscureText: true), const SizedBox(height: AppSpacing.md), HBInput(controller: _confirm, label: 'auth.password_reset.confirm_password'.tr(), obscureText: true), if (_error != null) Text(_error!.messageKey.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))])), actions: [HBButton.ghost(label: 'common.back'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'auth.password_reset.save'.tr(), onPressed: _save, isLoading: _loading)]);
}