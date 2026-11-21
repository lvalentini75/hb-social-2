import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/shell/widgets/app_header.dart';
import 'package:hb_social/shell/widgets/app_sidebar.dart';
import 'package:hb_social/shell/widgets/chat_dock.dart';
import 'package:hb_social/shell/widgets/right_rail.dart';

enum WebPageLayout { feed, standard, wide }

class WebPageLayoutConfig {
  final WebPageLayout kind;
  final String? contextTitleKey;
  final String? contextBodyKey;

  const WebPageLayoutConfig(this.kind, {this.contextTitleKey, this.contextBodyKey});

  static WebPageLayoutConfig forPath(String path) {
    if (path == AppRoutes.home) return const WebPageLayoutConfig(WebPageLayout.feed);
    if (path == AppRoutes.marketplace || path == AppRoutes.map || path == AppRoutes.huntingCalendar) return const WebPageLayoutConfig(WebPageLayout.wide);
    if (path == AppRoutes.groups) return const WebPageLayoutConfig(WebPageLayout.standard, contextTitleKey: 'groups.rail_why_title', contextBodyKey: 'groups.rail_why_message');
    if (path == AppRoutes.pages) return const WebPageLayoutConfig(WebPageLayout.standard, contextTitleKey: 'pages.rail_verification_title', contextBodyKey: 'pages.rail_verification_message');
    if (path == AppRoutes.forum) return const WebPageLayoutConfig(WebPageLayout.standard, contextTitleKey: 'forum_rail.rules_title', contextBodyKey: 'forum_rail.rules_message');
    return const WebPageLayoutConfig(WebPageLayout.standard);
  }
}

/// PD4 web shell: page-coloured background, 64 px top bar, 240 px navigation
/// card and the fluid center column, with the 368 px rail where it fits.
class WebShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const WebShell({super.key, required this.currentIndex, required this.onDestinationSelected, required this.child});

  @override
  Widget build(BuildContext context) {
    final layout = WebPageLayoutConfig.forPath(GoRouterState.of(context).uri.path);
    return ColoredBox(
      color: LightModeColors.pageWeb,
      child: Stack(children: [
        Positioned.fill(child: Column(children: [
          AppHeader(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppBreakpoints.pageGutter),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppSidebar(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected),
              const SizedBox(width: AppBreakpoints.columnGap),
              Expanded(child: WebShellColumns(layout: layout, child: child)),
            ]),
          )),
        ])),
        const ChatDock(),
      ]),
    );
  }
}

class WebShellColumns extends StatelessWidget {
  final WebPageLayoutConfig layout;
  final Widget child;

  const WebShellColumns({super.key, required this.layout, required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    if (layout.kind == WebPageLayout.wide) {
      return Align(alignment: Alignment.topLeft, child: SizedBox(width: constraints.maxWidth, height: constraints.maxHeight, child: child));
    }
    final canShowRail = MediaQuery.sizeOf(context).width > AppBreakpoints.railBreakpoint && constraints.maxWidth >= AppBreakpoints.feedMinWidth + AppBreakpoints.railWidth + AppBreakpoints.columnGap;
    if (!canShowRail) {
      final width = constraints.maxWidth < AppBreakpoints.feedMinWidth ? constraints.maxWidth : constraints.maxWidth.clamp(AppBreakpoints.feedMinWidth, AppBreakpoints.feedMaxWidth).toDouble();
      return Align(alignment: Alignment.topLeft, child: SizedBox(width: width, height: constraints.maxHeight, child: child));
    }
    final available = constraints.maxWidth - AppBreakpoints.railWidth - AppBreakpoints.columnGap;
    final centerWidth = available.clamp(AppBreakpoints.feedMinWidth, AppBreakpoints.feedMaxWidth).toDouble();
    final contextCard = layout.contextTitleKey == null ? null : RailContextCard(title: layout.contextTitleKey!.tr(), body: layout.contextBodyKey!.tr());
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: Align(alignment: Alignment.topCenter, child: SizedBox(width: centerWidth, child: child))),
      const SizedBox(width: AppBreakpoints.columnGap),
      SizedBox(width: AppBreakpoints.railWidth, child: Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: RightRail(contextCard: contextCard))),
    ]);
  });
}
