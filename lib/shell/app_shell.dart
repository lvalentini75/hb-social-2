import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/shell/mobile_shell.dart';
import 'package:hb_social/shell/web_shell.dart';

/// The single navigation shell (and the only [Scaffold]) wrapping every
/// in-app destination. Above 900px it renders [WebShell]; below it renders
/// [MobileShell]. Child pages never create a Scaffold of their own.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _goToBranch(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightModeColors.lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.mobile;
          if (isWide) {
            return WebShell(currentIndex: navigationShell.currentIndex, onDestinationSelected: _goToBranch, child: navigationShell);
          }
          return MobileShell(currentIndex: navigationShell.currentIndex, onDestinationSelected: _goToBranch, child: navigationShell);
        },
      ),
    );
  }
}
