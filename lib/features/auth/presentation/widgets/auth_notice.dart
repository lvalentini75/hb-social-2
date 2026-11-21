import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Explains that sign-in and sign-up become functional once Supabase is
/// connected (P03). Shown instead of ever simulating a session.
class AuthNotice extends StatelessWidget {
  final String messageKey;
  final bool isError;
  final Map<String, String> namedArgs;

  const AuthNotice({super.key, this.messageKey = 'auth.backend_notice', this.isError = false, this.namedArgs = const {}});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: isError ? LightModeColors.lightError.withValues(alpha: 0.08) : LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.info_outline_rounded, size: 20, color: isError ? LightModeColors.lightError : LightModeColors.lightForest),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              messageKey.tr(namedArgs: namedArgs),
              style: context.textStyles.bodySmall?.withColor(isError ? LightModeColors.lightError : LightModeColors.lightForest),
            ),
          ),
        ],
      ),
    );
  }
}
