import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';

/// The 340px right rail on wide layouts: five explicit-empty-state panels
/// (active now, messages, nearby events, trending, suggestions). None of
/// this activity exists yet, so every panel says so plainly instead of
/// showing sample people, messages, events or hashtags.
class RightRail extends StatelessWidget {
  const RightRail({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _RailCard(title: 'home.rail_active_now_title'.tr(), emptyMessage: 'home.rail_active_now_empty'.tr()),
        const SizedBox(height: AppSpacing.md),
        _RailCard(
          title: 'nav.messages'.tr(),
          titleAction: 'home.rail_messages_all'.tr(),
          onTitleAction: () => context.go(AppRoutes.messages),
          emptyMessage: 'home.rail_messages_empty'.tr(),
        ),
        const SizedBox(height: AppSpacing.md),
        _RailCard(
          title: 'home.rail_events_title'.tr(),
          emptyMessage: 'home.rail_events_empty'.tr(),
          ctaButton: HBButton.soft(
            label: 'home.today_hunting_set_zone'.tr(),
            size: HBButtonSize.sm,
            onPressed: () => context.go(AppRoutes.hunting),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RailCard(title: 'home.rail_trending_title'.tr(), emptyMessage: 'home.rail_trending_empty'.tr()),
        const SizedBox(height: AppSpacing.md),
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: Text('home.suggestions_title'.tr(), style: context.textStyles.titleMedium),
              ),
              HBEmptyState(
                icon: Icons.person_add_alt_outlined,
                title: 'home.suggestions_empty_title'.tr(),
                message: 'home.suggestions_empty_message'.tr(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact rail panel: an uppercase label, an optional trailing text
/// action, an explicit empty message and an optional CTA button.
class _RailCard extends StatelessWidget {
  final String title;
  final String? titleAction;
  final VoidCallback? onTitleAction;
  final String emptyMessage;
  final Widget? ctaButton;

  const _RailCard({required this.title, required this.emptyMessage, this.titleAction, this.onTitleAction, this.ctaButton});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ),
              if (titleAction != null)
                GestureDetector(
                  onTap: onTitleAction,
                  child: Text(titleAction!, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightForest)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(emptyMessage, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
          if (ctaButton != null) ...[const SizedBox(height: AppSpacing.sm), ctaButton!],
        ],
      ),
    );
  }
}
