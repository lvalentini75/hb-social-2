import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';

/// Shared two-column web layout: a center column (max [AppBreakpoints.feedMaxWidth])
/// and an optional [AppBreakpoints.railWidth] right rail, separated by a
/// fixed gap. The rail only appears from [AppBreakpoints.railBreakpoint] up;
/// below that it is dropped entirely rather than stacked under the center
/// column. Every page builds its own `rail` (if any) — there is no longer a
/// single shared right rail injected by the shell.
class PageColumns extends StatelessWidget {
  final Widget center;
  final Widget? rail;

  const PageColumns({super.key, required this.center, this.rail});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = rail != null && MediaQuery.sizeOf(context).width >= AppBreakpoints.railBreakpoint;
        final maxWidth = showRail ? AppBreakpoints.feedMaxWidth + AppSpacing.lg + AppBreakpoints.railWidth : AppBreakpoints.feedMaxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: showRail
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: center),
                      const SizedBox(width: AppSpacing.lg),
                      SizedBox(
                        width: AppBreakpoints.railWidth,
                        child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), child: rail!),
                      ),
                    ],
                  )
                : center,
          ),
        );
      },
    );
  }
}

/// A rail panel used by page-specific right columns: an uppercase 11/700
/// textTertiary label, a title/body and optional action — the same visual
/// convention as the Home right rail.
class PageRailCard extends StatelessWidget {
  final String label;
  final Widget child;

  const PageRailCard({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
