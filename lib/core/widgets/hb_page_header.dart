import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// PD4b uniform page heading for every list page inside the shell.
///
/// Mobile: display title 34/800/-0.8 with a 15/400 secondary subtitle.
/// Web: heading title 28/700 on the left and the primary pill action on the
/// right. The hierarchy comes from weight and spacing, never from a second
/// typeface.
class HBPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? menu;

  const HBPageHeader({super.key, required this.title, this.subtitle, this.action, this.menu});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final titleStyle = (compact ? AppText.display : AppText.heading).withColor(LightModeColors.text);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: AppText.body.withColor(LightModeColors.textSecondary))],
      ])),
      if (action != null) ...[const SizedBox(width: AppSpacing.md), action!],
      if (menu != null) ...[const SizedBox(width: AppSpacing.xs), menu!],
    ]);
  }
}
