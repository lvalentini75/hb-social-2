import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/app_buttons.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/auth/providers/user_providers.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_follow.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_interests.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_location.dart';
import 'package:hb_social/features/onboarding/providers/onboarding_providers.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  bool _canProceed(OnboardingState state) {
    if (state.step == 0) return state.countryCode != null;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    late final String title;
    late final String subtitle;
    late final Widget stepContent;
    switch (state.step) {
      case 0:
        title = 'onboarding.location_title'.tr();
        subtitle = 'onboarding.location_subtitle'.tr();
        stepContent = StepLocation(
          countryCode: state.countryCode,
          regionCode: state.regionCode,
          onCountryChanged: notifier.selectCountry,
          onRegionChanged: notifier.selectRegion,
        );
        break;
      case 1:
        title = 'onboarding.interests_title'.tr();
        subtitle = 'onboarding.interests_subtitle'.tr();
        stepContent = StepInterests(selected: state.interestIds, onToggle: notifier.toggleInterest);
        break;
      default:
        title = 'onboarding.follow_title'.tr();
        subtitle = 'onboarding.follow_subtitle'.tr();
        stepContent = const StepFollow();
    }

    final isLastStep = state.step == 2;

    Future<void> handlePrimaryAction() async {
      if (!isLastStep) {
        notifier.nextStep();
        return;
      }
      await ref.read(currentUserProvider.notifier).completeOnboarding(
            countryCode: state.countryCode ?? '',
            regionCode: state.regionCode,
            interestIds: state.interestIds.toList(),
          );
      if (context.mounted) context.go(AppRoutes.home);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (state.step == 0) {
                        context.go(AppRoutes.welcome);
                      } else {
                        notifier.previousStep();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, color: LightModeColors.lightOnSurface),
                  ),
                  const Spacer(),
                  const HbLogo(size: 32),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OnboardingStepHeader(step: state.step, title: title, subtitle: subtitle),
                        const SizedBox(height: AppSpacing.xl),
                        stepContent,
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AppPrimaryButton(
                    label: isLastStep ? 'common.finish'.tr() : 'common.next'.tr(),
                    onPressed: _canProceed(state) ? handlePrimaryAction : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
