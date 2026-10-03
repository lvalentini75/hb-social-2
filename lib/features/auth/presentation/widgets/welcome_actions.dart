import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_legal_note.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_social_buttons.dart';

/// Primary actions shown on the right side of the Welcome screen (or below
/// the headline on mobile): create account, log in, social sign-in and the
/// legal note. The HB logo and any title/subtitle are rendered by
/// [WelcomePage] itself, never inside this widget.
///
/// In debug builds only, a ghost link lets the developer browse the app
/// shell without an account; it does not exist in release builds.
class WelcomeActions extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final VoidCallback onExploreApp;

  const WelcomeActions({super.key, required this.onCreateAccount, required this.onLogin, required this.onExploreApp});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HBButton.primary(label: 'welcome.create_account'.tr(), onPressed: onCreateAccount),
        const SizedBox(height: AppSpacing.sm),
        HBButton.secondary(label: 'welcome.login'.tr(), onPressed: onLogin),
        const SizedBox(height: AppSpacing.lg),
        const WelcomeSocialButtons(),
        const SizedBox(height: AppSpacing.lg),
        const WelcomeLegalNote(),
        if (Env.previewEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: HBButton.ghost(label: 'welcome.explore_app'.tr(), size: HBButtonSize.sm, onPressed: onExploreApp),
          ),
        ],
      ],
    );
  }
}
