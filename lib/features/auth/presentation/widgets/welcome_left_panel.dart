import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_value_props.dart';

/// Introductory copy and value propositions shown over or below the photo.
class WelcomeIntroPanel extends StatelessWidget {
  const WelcomeIntroPanel({super.key, this.compact = false, this.onImage = false, this.showBrand = true, this.showHeadline = true});

  final bool compact;
  final bool onImage;
  final bool showBrand;
  final bool showHeadline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: onImage ? LightModeColors.overlayStrong : Colors.white, borderRadius: onImage ? BorderRadius.circular(AppRadius.xl) : null),
      padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.lg : AppSpacing.xl, vertical: compact ? AppSpacing.lg : AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              if (showBrand) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HbLogo(size: 40),
                    const SizedBox(width: AppSpacing.sm),
                    Text('app.name'.tr(), style: context.textStyles.titleMedium?.copyWith(color: onImage ? Colors.white : null)),
                  ],
                ),
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              ],
              if (showHeadline) ...[
                Text(
                  'welcome.headline'.tr(),
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: (compact ? context.textStyles.headlineMedium : context.textStyles.displayLarge?.copyWith(fontSize: 50, height: 1.05, letterSpacing: -1.2))?.copyWith(color: onImage ? Colors.white : null),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                'welcome.description'.tr(),
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: context.textStyles.bodyLarge?.copyWith(height: 1.45, color: onImage ? Colors.white : LightModeColors.lightOnSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              WelcomeValueProps(
                iconColor: onImage ? Colors.white : colors.primary,
                iconBackground: onImage ? LightModeColors.overlay : colors.primaryContainer,
                textColor: onImage ? Colors.white : LightModeColors.lightOnSurface,
                alignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Immersive photographic panel shown in the center of the Welcome screen.
class WelcomeLeftPanel extends StatelessWidget {
  const WelcomeLeftPanel({super.key});

  @override
  Widget build(BuildContext context) => Image.asset('assets/images/hunter_dog.jpg', width: double.infinity, height: double.infinity, fit: BoxFit.cover, alignment: Alignment.center, excludeFromSemantics: true);
}

/// Compact centered photo used between the intro and actions on smaller screens.
class WelcomeMobileHero extends StatelessWidget {
  const WelcomeMobileHero({super.key, this.height = 320, this.expandedCopy = false});

  final double height;
  final bool expandedCopy;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/hunter_dog.jpg', fit: BoxFit.cover, alignment: Alignment.center, excludeFromSemantics: true),
        const ColoredBox(color: LightModeColors.scrimSoft),
        if (expandedCopy)
          const Align(alignment: Alignment.centerLeft, child: WelcomeIntroPanel(onImage: true, showBrand: false))
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HbLogo(size: 36),
                    const SizedBox(width: AppSpacing.sm),
                    Text('app.name'.tr(), style: context.textStyles.titleMedium?.copyWith(color: Colors.white)),
                  ],
                ),
                Text('welcome.headline'.tr(), style: context.textStyles.headlineMedium?.copyWith(color: Colors.white, height: 1.08)),
              ],
            ),
          ),
      ],
    ),
  );
}
