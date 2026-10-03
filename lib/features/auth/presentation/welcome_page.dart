import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_actions.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_left_panel.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_value_props.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.mobile;
            final actions = WelcomeActions(
              onCreateAccount: () => context.go(AppRoutes.signup),
              onLogin: () => context.go(AppRoutes.login),
              onExploreApp: () => context.go(AppRoutes.home),
            );
            if (isWide) {
              return Row(
                children: [
                  const Expanded(child: WelcomeLeftPanel()),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: HbLogo(size: 72)),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'welcome.title'.tr(),
                                textAlign: TextAlign.center,
                                style: context.textStyles.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'welcome.subtitle'.tr(),
                                textAlign: TextAlign.center,
                                style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              actions,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const HbLogo(size: 56),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'welcome.headline'.tr(),
                    textAlign: TextAlign.center,
                    style: context.textStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  WelcomeValueProps(
                    iconColor: colors.primary,
                    iconBackground: colors.primaryContainer,
                    textColor: LightModeColors.lightOnSurface,
                    alignment: CrossAxisAlignment.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  actions,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
