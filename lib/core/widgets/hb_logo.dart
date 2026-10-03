import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// The square "HB" brand mark used on the welcome screen and the app header.
class HbLogo extends StatelessWidget {
  final double size;
  final Color background;
  final Color foreground;

  const HbLogo({
    super.key,
    this.size = 56,
    this.background = LightModeColors.lightPrimary,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.28)),
      alignment: Alignment.center,
      child: Text(
        'HB',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
