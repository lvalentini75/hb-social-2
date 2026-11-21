import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';

/// Compatibility wrapper for page content.
///
/// Web columns are owned exclusively by [WebShell]. Legacy sizing and rail
/// arguments remain temporarily source-compatible but no longer create a
/// local grid.
class PageColumns extends StatelessWidget {
  final Widget center;
  final Widget? rail;

  /// Narrow layouts are edge-to-edge: the shell adds no horizontal padding.
  /// Pages that are not media-first keep a [AppSpacing.md] gutter; set this to
  /// false when the page manages its own gutters (e.g. the full-bleed feed).
  final bool gutter;
  final double centerMaxWidth;
  final double centerMinWidth;
  final double railMinWidth;
  final double railMaxWidth;
  final double railBreakpoint;

  const PageColumns({super.key, required this.center, this.rail, this.gutter = true, this.centerMaxWidth = AppBreakpoints.feedMaxWidth, this.centerMinWidth = 0, this.railMinWidth = AppBreakpoints.railWidth, this.railMaxWidth = AppBreakpoints.railWidth, this.railBreakpoint = AppBreakpoints.railBreakpoint, layout});

  @override
  Widget build(BuildContext context) {
    final mobilePadding = gutter && MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? AppSpacing.md : 0.0;
    return Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.symmetric(horizontal: mobilePadding), child: SizedBox(width: double.infinity, child: center)));
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
            label,
            style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
