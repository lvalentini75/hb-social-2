import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// The square "HB" brand mark (PD4): Bosco square, radius 12, white "HB" 700.
class HbLogo extends StatelessWidget {
  final double size;
  final Color background;
  final Color foreground;

  const HbLogo({
    super.key,
    this.size = 44,
    this.background = LightModeColors.bosco,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.nav)),
    alignment: Alignment.center,
    child: Text('HB', style: appFont(size * 0.45, FontWeight.w700, spacing: -0.4, color: foreground)),
  );
}
