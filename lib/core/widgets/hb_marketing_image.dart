import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Marketing imagery (hero, zone, invite, community) is a static asset the
/// developer uploads. When the asset is missing the box falls back to a solid
/// Bosco fill with the same texts — never a gradient, never a sample photo.
class HBMarketingImage extends StatelessWidget {
  final String asset;
  final double? height;
  final double radius;
  final Widget? overlayChild;
  final bool dimLeft;
  final VoidCallback? onTap;

  const HBMarketingImage({super.key, required this.asset, this.height, this.radius = AppRadius.cardWeb, this.overlayChild, this.dimLeft = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Stack(fit: StackFit.expand, children: [
      Image.asset(asset, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const ColoredBox(color: LightModeColors.bosco)),
      if (dimLeft)
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [LightModeColors.overlayStrong, LightModeColors.overlay])))
      else
        const ColoredBox(color: LightModeColors.overlay),
      if (overlayChild != null) overlayChild!,
    ]);
    final clipped = ClipRRect(borderRadius: BorderRadius.circular(radius), child: SizedBox(height: height, width: double.infinity, child: content));
    if (onTap == null) return clipped;
    return InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: clipped);
  }
}
