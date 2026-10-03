import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/auth/presentation/widgets/auth_notice.dart';

/// Social sign-in row shown below the primary Welcome actions, under a
/// labelled divider. No provider is ever called here: tapping any button
/// just reveals the same "backend not connected" [AuthNotice] shown on
/// Login/Signup, since sign-in activates with Supabase (P03).
class WelcomeSocialButtons extends StatefulWidget {
  const WelcomeSocialButtons({super.key});

  @override
  State<WelcomeSocialButtons> createState() => _WelcomeSocialButtonsState();
}

class _WelcomeSocialButtonsState extends State<WelcomeSocialButtons> {
  bool _showNotice = false;

  void _handleTap() => setState(() => _showNotice = true);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: LightModeColors.lightDivider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'welcome.or_continue_with'.tr(),
                style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary),
              ),
            ),
            const Expanded(child: Divider(color: LightModeColors.lightDivider)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: HBButton.secondary(
                label: 'welcome.google'.tr(),
                icon: Icons.g_mobiledata_rounded,
                size: HBButtonSize.sm,
                onPressed: _handleTap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: HBButton.secondary(
                label: 'welcome.apple'.tr(),
                icon: Icons.apple_rounded,
                size: HBButtonSize.sm,
                onPressed: _handleTap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: HBButton.secondary(
                label: 'welcome.facebook'.tr(),
                icon: Icons.facebook_rounded,
                size: HBButtonSize.sm,
                onPressed: _handleTap,
              ),
            ),
          ],
        ),
        if (_showNotice) ...[
          const SizedBox(height: AppSpacing.md),
          const AuthNotice(),
        ],
      ],
    );
  }
}
