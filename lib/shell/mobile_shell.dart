import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/shell/widgets/app_bottom_nav.dart';
import 'package:hb_social/shell/widgets/mobile_top_bar.dart';

/// Narrow (< 900px) layout: a compact top bar, the page, and the 5-slot
/// bottom navigation bar with the central create button.
class MobileShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const MobileShell({super.key, required this.currentIndex, required this.onDestinationSelected, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          MobileTopBar(onDestinationSelected: onDestinationSelected),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: child,
            ),
          ),
          AppBottomNav(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected),
        ],
      ),
    );
  }
}
