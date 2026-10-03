import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Small pill used for moderation/admin statuses. Five content statuses
/// (pending/approved/rejected/info/neutral) plus three admin role variants.
enum HBStatusKind { pending, approved, rejected, info, neutral, moderator, admin, superAdmin }

class HBStatusChip extends StatelessWidget {
  final HBStatusKind kind;
  final String label;

  const HBStatusChip({super.key, required this.kind, required this.label});

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    switch (kind) {
      case HBStatusKind.pending:
        background = LightModeColors.lightWarning.withValues(alpha: 0.12);
        foreground = LightModeColors.lightWarning;
        break;
      case HBStatusKind.approved:
        background = LightModeColors.lightSuccess.withValues(alpha: 0.12);
        foreground = LightModeColors.lightSuccess;
        break;
      case HBStatusKind.rejected:
        background = LightModeColors.lightError.withValues(alpha: 0.12);
        foreground = LightModeColors.lightError;
        break;
      case HBStatusKind.info:
        background = LightModeColors.lightInfo.withValues(alpha: 0.12);
        foreground = LightModeColors.lightInfo;
        break;
      case HBStatusKind.neutral:
        background = LightModeColors.lightBackgroundSoft;
        foreground = LightModeColors.lightOnSurfaceVariant;
        break;
      case HBStatusKind.moderator:
        background = LightModeColors.lightInfo.withValues(alpha: 0.12);
        foreground = LightModeColors.lightInfo;
        break;
      case HBStatusKind.admin:
        background = LightModeColors.lightPrimarySoft;
        foreground = LightModeColors.lightPrimary;
        break;
      case HBStatusKind.superAdmin:
        background = LightModeColors.lightForest;
        foreground = Colors.white;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: context.textStyles.labelSmall?.withColor(foreground).semiBold),
    );
  }
}
