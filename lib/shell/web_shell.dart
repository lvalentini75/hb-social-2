import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/shell/widgets/app_header.dart';
import 'package:hb_social/shell/widgets/app_sidebar.dart';

/// Wide (>= 900px) layout: a 64px header, a fixed 260px sidebar and the
/// content area. There is no shell-level right rail anymore: each page
/// builds its own right column (if any) via `PageColumns`.
class WebShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const WebShell({super.key, required this.currentIndex, required this.onDestinationSelected, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSidebar(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected),
              Expanded(
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: child),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
