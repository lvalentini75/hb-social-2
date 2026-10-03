import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_value_props.dart';

/// Dark green brand panel shown on the left side of the Welcome screen on
/// wide (web) layouts, with the headline and the three value propositions.
class WelcomeLeftPanel extends StatelessWidget {
  const WelcomeLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LightModeColors.lightForest,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'welcome.headline'.tr(),
                style: context.textStyles.headlineLarge?.withColor(Colors.white),
              ),
              const SizedBox(height: AppSpacing.xxl),
              WelcomeValueProps(
                iconColor: Colors.white,
                iconBackground: Colors.white.withValues(alpha: 0.12),
                textColor: Colors.white.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
