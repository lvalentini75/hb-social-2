import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/shell/mobile_shell.dart';
import 'package:hb_social/shell/web_shell.dart';
import 'package:hb_social/shell/ads_manager_shell.dart';

/// The single navigation shell (and the only [Scaffold]) wrapping every
/// in-app destination. Above 900px it renders [WebShell]; below it renders
/// [MobileShell]. Child pages never create a Scaffold of their own.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _goToBranch(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAds = GoRouterState.of(context).uri.path == AppRoutes.ads || GoRouterState.of(context).uri.path.startsWith('${AppRoutes.ads}/');
    return Scaffold(
      backgroundColor: LightModeColors.pageMobile,
      body: Stack(children: [Positioned.fill(child: LayoutBuilder(
        builder: (context, constraints) {
          if (isAds) return AdsManagerShell(child: navigationShell);
          final isWide = constraints.maxWidth >= AppBreakpoints.mobile;
          if (isWide) {
            return WebShell(currentIndex: navigationShell.currentIndex, onDestinationSelected: _goToBranch, child: navigationShell);
          }
          return MobileShell(currentIndex: navigationShell.currentIndex, onDestinationSelected: _goToBranch, child: navigationShell);
        },
      )), if (ref.watch(realtimeReconnectingProvider)) Positioned(top: MediaQuery.paddingOf(context).top + AppSpacing.sm, left: 0, right: 0, child: Center(child: HBStatusChip(kind: HBStatusKind.neutral, label: 'presence.reconnecting'.tr())))]),
    );
  }
}
