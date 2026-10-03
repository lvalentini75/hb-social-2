import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/app_buttons.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/core/widgets/social_auth_buttons.dart';

/// Logo, primary actions and social sign-in options shown on the right side
/// of the Welcome screen (or below the headline on mobile).
class WelcomeActions extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const WelcomeActions({super.key, required this.onCreateAccount, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: HbLogo(size: 64)),
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(label: 'welcome.create_account'.tr(), onPressed: onCreateAccount),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(label: 'welcome.login'.tr(), onPressed: onLogin),
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
          child: Text(
            'welcome.adults_only'.tr(),
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.withColor(colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
