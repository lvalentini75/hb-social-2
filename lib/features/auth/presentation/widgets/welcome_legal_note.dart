import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Legal disclaimer shown below the Welcome screen actions. The two
/// highlighted spans are visually emphasized but not tappable yet: there are
/// no Terms of Service or Privacy Policy pages in the app.
class WelcomeLegalNote extends StatelessWidget {
  const WelcomeLegalNote({super.key});

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightTextTertiary);
    final linkStyle = context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightOnSurfaceVariant, fontWeight: FontWeight.bold);
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: 'welcome.legal_note_prefix'.tr()),
          TextSpan(text: 'welcome.terms_of_service'.tr(), style: linkStyle),
          TextSpan(text: 'welcome.legal_note_middle'.tr()),
          TextSpan(text: 'welcome.privacy_policy'.tr(), style: linkStyle),
          TextSpan(text: 'welcome.legal_note_suffix'.tr()),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
