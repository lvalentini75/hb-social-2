import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Small identity badge shown next to a verified name.
enum HBBadgeKind { verified, gunShop, guide, association, error }

class HBBadge extends StatelessWidget {
  final HBBadgeKind? kind;
  final int? count;
  final String? label;
  final bool emphasized;
  final String? verificationLevel;
  final DateTime? verifiedAt;

  const HBBadge({super.key, required HBBadgeKind this.kind}) : count = null, label = null, emphasized = false, verificationLevel = null, verifiedAt = null;
  const HBBadge.count({super.key, required int this.count}) : kind = null, label = null, emphasized = false, verificationLevel = null, verifiedAt = null;
  const HBBadge.label({super.key, required String this.label, this.emphasized = false}) : kind = null, count = null, verificationLevel = null, verifiedAt = null;
  const HBBadge.verification({super.key, required String level, this.verifiedAt}) : verificationLevel = level, kind = null, count = null, label = null, emphasized = false;

  @override
  Widget build(BuildContext context) {
    if (count != null) return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: LightModeColors.lightPrimary, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text('$count', style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)));
    if (label != null) return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: emphasized ? LightModeColors.lightPrimarySoft : LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text(label!, style: context.textStyles.labelSmall?.copyWith(color: emphasized ? LightModeColors.lightForest : LightModeColors.lightOnSurfaceVariant, fontWeight: FontWeight.w700)));
    final resolvedKind = verificationLevel == null ? kind! : switch (verificationLevel) {'gun_shop' => HBBadgeKind.gunShop, 'guide' => HBBadgeKind.guide, 'association' => HBBadgeKind.association, _ => HBBadgeKind.verified};
    late final Color color;
    late final IconData icon;
    switch (resolvedKind) {
      case HBBadgeKind.verified:
        color = LightModeColors.lightAccentBrass;
        icon = Icons.star_outline_rounded;
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
      case HBBadgeKind.error:
        color = LightModeColors.lightError;
        icon = Icons.shield_rounded;
        break;
    }
    final badge = Icon(icon, size: resolvedKind == HBBadgeKind.verified ? 14 : 16, color: color);
    if (verificationLevel == null) return badge;
    final date = verifiedAt == null ? null : DateFormat.yMMMd(context.locale.languageCode).format(verifiedAt!.toLocal());
    final type = 'verification.badge.${verificationLevel!}'.tr();
    final tooltip = date == null ? type : 'verification.badge_tooltip'.tr(namedArgs: {'type': type, 'date': date});
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(type, style: context.textStyles.titleLarge), if (date != null) ...[const SizedBox(height: AppSpacing.xs), Text(tooltip)]])),
                ],
              ),
            ),
          ),
        ),
        child: badge,
      ),
    );
  }
}
