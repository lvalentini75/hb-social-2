import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';

/// Draws an in-app first frame while an authenticated user's private context loads.
class AuthBootstrapGate extends ConsumerWidget {
  final Widget child;

  const AuthBootstrapGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session.isLoading) return const AuthBootstrapLoadingPage();
    if (session.hasError) return AuthBootstrapErrorPage(onSignOut: () => _signOut(context, ref));
    if (session.value == null) return child;

    final authState = ref.watch(authProfileStateProvider);
    if (authState.isLoading) return const AuthBootstrapLoadingPage();
    if (authState.hasError || authState.value == null) return AuthBootstrapErrorPage(onSignOut: () => _signOut(context, ref));
    if (authState.value!.needsProfileSetup) return child;

    final profile = ref.watch(currentProfileProvider);
    final settings = ref.watch(privateUserSettingsProvider);
    if (profile.isLoading || settings.isLoading) return const AuthBootstrapLoadingPage();
    if (profile.hasError || settings.hasError || profile.value == null || settings.value == null) return AuthBootstrapErrorPage(onSignOut: () => _signOut(context, ref));
    return child;
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRoutes.welcome);
  }
}

class AuthBootstrapLoadingPage extends StatelessWidget {
  const AuthBootstrapLoadingPage({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: LightModeColors.lightBackground,
    child: Center(child: SizedBox(width: 280, child: Column(mainAxisSize: MainAxisSize.min, children: [HBSkeleton(height: 28, width: 180), SizedBox(height: AppSpacing.md), HBSkeleton(height: 14), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 14, width: 220)]))),
  );
}

class AuthBootstrapErrorPage extends StatelessWidget {
  final VoidCallback onSignOut;

  const AuthBootstrapErrorPage({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: LightModeColors.lightBackground,
    child: Center(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'auth.bootstrap_error_title'.tr(), message: 'auth.bootstrap_error_message'.tr(), action: HBButton.secondary(label: 'auth.logout'.tr(), onPressed: onSignOut))),
  );
}