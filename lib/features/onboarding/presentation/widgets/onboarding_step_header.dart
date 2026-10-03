import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/config/app_config.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Step progress indicator + title/subtitle shared by all three onboarding
/// steps.
class OnboardingStepHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;

  const OnboardingStepHeader({super.key, required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const total = AppConfig.onboardingStepCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(total, (index) {
            final isActive = index <= step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == total - 1 ? 0 : AppSpacing.xs),
                height: 4,
                decoration: BoxDecoration(
                  color: isActive ? colors.primary : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'onboarding.step_indicator'.tr(namedArgs: {'step': '${step + 1}', 'total': '$total'}),
          style: context.textStyles.labelMedium?.withColor(colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: context.textStyles.bodyMedium?.withColor(colors.onSurfaceVariant)),
      ],
    );
  }
}
