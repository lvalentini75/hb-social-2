import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

/// Legal disclaimer shown below the Welcome screen actions.
class WelcomeLegalNote extends StatelessWidget {
  const WelcomeLegalNote({super.key});

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightTextTertiary);
    final linkStyle = context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightOnSurfaceVariant, fontWeight: FontWeight.bold);
    return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('welcome.legal_note_prefix'.tr(), style: baseStyle), TextButton(onPressed: () => context.push('/legal/terms'), child: Text('welcome.terms_of_service'.tr(), style: linkStyle)), Text('welcome.legal_note_middle'.tr(), style: baseStyle), TextButton(onPressed: () => context.push('/legal/privacy'), child: Text('welcome.privacy_policy'.tr(), style: linkStyle)), Text('welcome.legal_note_suffix'.tr(), style: baseStyle)]);
  }
}
