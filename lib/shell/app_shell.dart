import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/auth/providers/user_providers.dart';
import 'package:hb_social/shell/widgets/app_bottom_nav.dart';
import 'package:hb_social/shell/widgets/app_header.dart';
import 'package:hb_social/shell/widgets/app_sidebar.dart';
import 'package:hb_social/shell/widgets/right_rail.dart';

/// The single navigation shell used by every signed-in screen (Home,
/// Profile, ...). On wide layouts it renders the web header + sidebar +
/// right rail around a fixed-width center column; on narrow layouts it
/// renders a bottom navigation bar instead.
class AppShell extends ConsumerWidget {
  final String currentPath;
  final Widget child;

  const AppShell({super.key, required this.currentPath, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: LightModeColors.lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.mobile;
            if (isWide) {
              return Column(
                children: [
                  AppHeader(currentUser: currentUser),
                  const Divider(height: 1),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSidebar(currentPath: currentPath),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: AppBreakpoints.feedMaxWidth),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppBreakpoints.railWidth, child: RightRail()),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: child),
                AppBottomNav(currentPath: currentPath),
              ],
            );
          },
        ),
      ),
    );
  }
}
