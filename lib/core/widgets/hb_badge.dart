import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Small identity badge shown next to a name (verified, gun shop, guide,
/// association). Purely visual — no verification logic exists yet.
enum HBBadgeKind { verified, gunShop, guide, association }

class HBBadge extends StatelessWidget {
  final HBBadgeKind kind;

  const HBBadge({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    switch (kind) {
      case HBBadgeKind.verified:
        color = LightModeColors.lightSuccess;
        icon = Icons.verified_rounded;
        break;
      case HBBadgeKind.gunShop:
        color = LightModeColors.lightInfo;
        icon = Icons.storefront_rounded;
        break;
      case HBBadgeKind.guide:
        color = LightModeColors.lightWarning;
        icon = Icons.military_tech_rounded;
        break;
      case HBBadgeKind.association:
        color = LightModeColors.lightOnSurfaceVariant;
        icon = Icons.groups_rounded;
        break;
    }
    return Icon(icon, size: 16, color: color);
  }
}
