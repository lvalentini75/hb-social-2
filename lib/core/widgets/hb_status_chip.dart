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
    late final Color foreground;
    switch (kind) {
      case HBStatusKind.pending:
        foreground = LightModeColors.lightWarning;
        break;
      case HBStatusKind.approved:
        foreground = LightModeColors.lightSuccess;
        break;
      case HBStatusKind.rejected:
        foreground = LightModeColors.lightError;
        break;
      case HBStatusKind.info:
        foreground = LightModeColors.lightInfo;
        break;
      case HBStatusKind.neutral:
        foreground = LightModeColors.lightNeutralStatus;
        break;
      case HBStatusKind.moderator:
        foreground = LightModeColors.lightInfo;
        break;
      case HBStatusKind.admin:
        foreground = LightModeColors.lightPrimary;
        break;
      case HBStatusKind.superAdmin:
        foreground = LightModeColors.lightForest;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: foreground, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightOnSurface).medium)]),
    );
  }
}
