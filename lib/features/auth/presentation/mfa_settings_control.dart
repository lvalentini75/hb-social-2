import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/settings/presentation/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MfaSettingsControl extends ConsumerWidget {
  const MfaSettingsControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(verifiedMfaFactorsProvider).when(
    loading: () => SettingsRow(icon: Icons.phonelink_lock_outlined, title: 'auth.mfa.settings_title'.tr(), subtitle: 'common.loading'.tr()),
    error: (_, __) => SettingsRow(icon: Icons.phonelink_lock_outlined, title: 'auth.mfa.settings_title'.tr(), subtitle: 'errors.network'.tr()),
    data: (factors) => SettingsRow(
      icon: Icons.phonelink_lock_outlined,
      title: 'auth.mfa.settings_title'.tr(),
      subtitle: (factors.isEmpty ? 'auth.mfa.inactive' : 'auth.mfa.active').tr(),
      trailing: factors.isEmpty
          ? HBButton.soft(label: 'auth.mfa.enable'.tr(), size: HBButtonSize.sm, onPressed: () => context.push(AppRoutes.mfaEnroll))
          : HBButton.soft(label: 'auth.mfa.disable'.tr(), size: HBButtonSize.sm, onPressed: () => showDialog<void>(context: context, builder: (_) => MfaDisableDialog(factor: factors.first))),
    ),
  );
}

class MfaDisableDialog extends ConsumerStatefulWidget {
  final Factor factor;
  const MfaDisableDialog({super.key, required this.factor});
  @override
  ConsumerState<MfaDisableDialog> createState() => _MfaDisableDialogState();
}

class _MfaDisableDialogState extends ConsumerState<MfaDisableDialog> {
  final _code = TextEditingController();
  AppException? _error;
  bool _loading = false;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _disable() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authSecurityRepositoryProvider).unenroll(widget.factor.id, _code.text);
      ref.invalidate(verifiedMfaFactorsProvider);
      if (mounted) context.pop();
    } on AppException catch (error) { if (mounted) setState(() => _error = error); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('auth.mfa.disable_title'.tr()), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('auth.mfa.disable_message'.tr()), const SizedBox(height: AppSpacing.md), HBInput(controller: _code, label: 'auth.mfa.code'.tr(), keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [FilteringTextInputFormatter.digitsOnly]), if (_error != null) Text(_error!.messageKey.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))]), actions: [HBButton.ghost(label: 'common.back'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'auth.mfa.disable'.tr(), onPressed: _disable, isLoading: _loading)]);
}