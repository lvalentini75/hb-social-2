import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class MfaChallengePage extends ConsumerStatefulWidget {
  final String destination;
  const MfaChallengePage({super.key, this.destination = AppRoutes.home});

  @override
  ConsumerState<MfaChallengePage> createState() => _MfaChallengePageState();
}

class _MfaChallengePageState extends ConsumerState<MfaChallengePage> {
  final _code = TextEditingController();
  bool _loading = false;
  AppException? _error;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_code.text.length != 6) { setState(() => _error = const AppException('errors.mfa_invalid_code')); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authSecurityRepositoryProvider).challenge(_code.text);
      ref.invalidate(mfaChallengeRequiredProvider);
      if (mounted) context.go(widget.destination);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: HBCard(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('auth.mfa.challenge_title'.tr(), style: context.textStyles.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('auth.mfa.challenge_subtitle'.tr()),
              const SizedBox(height: AppSpacing.lg),
              HBInput(controller: _code, label: 'auth.mfa.code'.tr(), keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              if (_error != null) ...[const SizedBox(height: AppSpacing.sm), Text(_error!.messageKey.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
              const SizedBox(height: AppSpacing.lg),
              HBButton.primary(label: 'auth.mfa.verify'.tr(), onPressed: _verify, isLoading: _loading),
              HBButton.ghost(label: 'auth.mfa.lost_access'.tr(), onPressed: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text('auth.mfa.lost_access'.tr()), content: Text('auth.mfa.support_message'.tr()), actions: [HBButton.ghost(label: 'common.back'.tr(), onPressed: () => dialogContext.pop())]))),
            ]),
          ),
        ),
      ),
    ),
  );
}