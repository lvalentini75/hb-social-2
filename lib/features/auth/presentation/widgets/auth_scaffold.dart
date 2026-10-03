import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';

/// Shared layout for the Login and Signup screens: a back button, the HB
/// logo, a title/subtitle pair and a centered, width-constrained form area.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                    onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
                    icon: const Icon(Icons.arrow_back_rounded, color: LightModeColors.lightOnSurface),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Center(child: HbLogo(size: 52)),
                        const SizedBox(height: AppSpacing.xl),
                        Text(title, textAlign: TextAlign.center, style: context.textStyles.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: context.textStyles.bodyMedium?.withColor(colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        child,
                      ],
                    ),
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
