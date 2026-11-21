import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_actions.dart';
import 'package:hb_social/features/auth/presentation/widgets/welcome_left_panel.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final heroHeight = (constraints.maxHeight * 0.5).clamp(300.0, 480.0);
            final actions = WelcomeActions(
              onCreateAccount: () => context.go(AppRoutes.signup),
              onLogin: () => context.go(AppRoutes.login),
              onExploreApp: () => context.go(AppRoutes.home),
            );
            if (isDesktop) return WelcomeDesktopLayout(actions: actions);
            return WelcomeMobileLayout(actions: actions, heroHeight: heroHeight);
          },
        ),
      ),
    );
  }
}

/// Split welcome layout used on desktop, with marketing imagery on the left.
class WelcomeDesktopLayout extends StatelessWidget {
  const WelcomeDesktopLayout({super.key, required this.actions});

  final Widget actions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Expanded(
        flex: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WelcomeLeftPanel(),
            ColoredBox(color: LightModeColors.scrimSoft),
            Align(alignment: Alignment.centerLeft, child: WelcomeIntroPanel(onImage: true)),
          ],
        ),
      ),
      Expanded(
        flex: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('welcome.title'.tr(), textAlign: TextAlign.center, style: context.textStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text('welcome.subtitle'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
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

/// Stacked welcome layout retained for smartphones.
class WelcomeMobileLayout extends StatelessWidget {
  const WelcomeMobileLayout({super.key, required this.actions, required this.heroHeight});

  final Widget actions;
  final double heroHeight;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('welcome.title'.tr(), textAlign: TextAlign.center, style: context.textStyles.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('welcome.subtitle'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
            ],
          ),
        ),
        WelcomeMobileHero(height: heroHeight),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              child: actions,
            ),
          ),
        ),
      ],
    ),
  );
}
