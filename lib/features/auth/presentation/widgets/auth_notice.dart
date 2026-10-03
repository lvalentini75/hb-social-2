import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Explains that sign-in and sign-up become functional once Supabase is
/// connected (P03). Shown instead of ever simulating a session.
class AuthNotice extends StatelessWidget {
  const AuthNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: LightModeColors.lightForest),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'auth.backend_notice'.tr(),
              style: context.textStyles.bodySmall?.withColor(LightModeColors.lightForest),
            ),
          ),
        ],
      ),
    );
  }
}
