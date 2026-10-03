import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/page_columns.dart';

/// One titled block of a [ListPageScaffold]'s [ListPageScaffold.sections]:
/// an h2 title, an optional trailing "see all" text action and the section
/// content (loading/error/empty state built by the caller).
class ListPageSection {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget content;

  const ListPageSection({required this.title, this.content = const SizedBox.shrink(), this.actionLabel, this.onAction});
}

/// Shared "list page" layout reused by Groups, Forum, Pages and Search: a
/// title row with an optional primary action, an optional filters row
/// (chips / segmented tabs), either a list of titled [sections] or a single
/// [body], and an optional page-specific right rail (rendered via
/// [PageColumns], hidden below [AppBreakpoints.railBreakpoint]). Never a
/// [Scaffold] itself — it is always placed inside the app shell.
class ListPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? filters;
  final List<ListPageSection>? sections;
  final Widget? body;
  final Widget? rail;

  const ListPageScaffold({super.key, required this.title, this.subtitle, this.action, this.filters, this.sections, this.body, this.rail});

  @override
  Widget build(BuildContext context) {
    final center = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(title, style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                         if (subtitle != null) ...[
                           const SizedBox(height: AppSpacing.xs),
                           Text(subtitle!, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
                         ],
                       ],
                     ),
                   ),
                  if (action != null) action!,
                ],
              ),
              if (filters != null) ...[const SizedBox(height: AppSpacing.md), filters!],
              const SizedBox(height: AppSpacing.lg),
              if (sections != null)
                for (final section in sections!) ...[
                  _SectionHeader(section: section),
                  const SizedBox(height: AppSpacing.md),
                  section.content,
                  const SizedBox(height: AppSpacing.xl),
                ]
              else if (body != null)
                body!,
            ],
          ),
        ),
      ],
    );
    return PageColumns(center: center, rail: rail);
  }
}

class _SectionHeader extends StatelessWidget {
  final ListPageSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(section.title, style: context.textStyles.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        if (section.actionLabel != null)
          GestureDetector(
            onTap: section.onAction,
            child: Text(section.actionLabel!, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightForest)),
          ),
      ],
    );
  }
}
