import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_value_props.dart';

const double _kPanelPadding = 72.0;

/// Dark green brand panel shown on the left side of the Welcome screen on
/// wide (web) layouts: brand mark top-left, hero headline, supporting
/// paragraph and the three value propositions centered in the remaining
/// space, over two decorative circles clipped by the panel edge.
class WelcomeLeftPanel extends StatelessWidget {
  const WelcomeLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: LightModeColors.lightForest,
        child: Stack(
          children: [
            const Positioned(top: -420, right: -420, child: _DecorCircle(diameter: 840)),
            const Positioned(bottom: -360, left: -360, child: _DecorCircle(diameter: 720)),
            Padding(
              padding: const EdgeInsets.all(_kPanelPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HbLogo(size: 40, background: Colors.white, foreground: LightModeColors.lightForest),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'app.name'.tr(),
                        style: context.textStyles.titleMedium?.withColor(Colors.white),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'welcome.headline'.tr(),
                              style: GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1.1, color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'welcome.description'.tr(),
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            WelcomeValueProps(
                              iconColor: Colors.white,
                              iconBackground: Colors.white.withValues(alpha: 0.12),
                              textColor: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative translucent circle used in the corners of [WelcomeLeftPanel].
class _DecorCircle extends StatelessWidget {
  final double diameter;

  const _DecorCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
    );
  }
}
