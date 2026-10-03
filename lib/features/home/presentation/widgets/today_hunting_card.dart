import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// "Oggi a caccia" — the one solid, dark card in the whole app. It will show
/// species chips, weather and sunrise/sunset once `hunting_calendars` exists
/// (P03/P04); until then every section is an explicit empty state on the
/// same dark surface, never fake calendar data. On wide layouts it expands
/// into three sections side by side (today / weather / season).
class TodayHuntingCard extends ConsumerWidget {
  final bool isWide;

  const TodayHuntingCard({super.key, this.isWide = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final zoneLabel = settings.countryCode == null
        ? 'home.today_hunting_status_unset'.tr()
        : 'hunting.country_region_unset'.tr(namedArgs: {'country': 'zone.country_${settings.countryCode!.toLowerCase()}'.tr()});
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: LightModeColors.lightForest, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.level2),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                         Expanded(flex: 2, child: _TodaySection(zoneLabel: zoneLabel)),
                        const _VerticalDivider(),
                        Expanded(child: _InfoSection(label: 'home.weather_label'.tr(), message: 'home.weather_empty'.tr())),
                        const _VerticalDivider(),
                        Expanded(child: _InfoSection(label: 'home.season_label'.tr(), message: 'home.season_empty'.tr())),
                      ],
                    ),
                  )
                else
                   _TodaySection(zoneLabel: zoneLabel),
                const SizedBox(height: AppSpacing.md),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                     _ZoneButton(onTap: () => context.go(AppRoutes.huntingZone)),
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                       onTap: () => context.go(AppRoutes.huntingCalendar),
                      child: Text('home.today_hunting_calendar_link'.tr(), style: context.textStyles.labelLarge?.withColor(Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final String zoneLabel;

  const _TodaySection({required this.zoneLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'home.today_hunting_title'.tr().toUpperCase(),
              style: context.textStyles.labelSmall?.withColor(Colors.white.withValues(alpha: 0.7)).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
            ),
            const SizedBox(width: AppSpacing.sm),
             _StatusPill(label: zoneLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('home.today_hunting_cta_title'.tr(), style: context.textStyles.titleMedium?.withColor(Colors.white)),
        const SizedBox(height: 2),
        Text('home.today_hunting_cta_subtitle'.tr(), style: context.textStyles.bodySmall?.withColor(Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: LightModeColors.lightTextTertiary, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.xs),
           Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String label;
  final String message;

  const _InfoSection({required this.label, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: context.textStyles.labelSmall?.withColor(Colors.white.withValues(alpha: 0.7)).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: context.textStyles.bodySmall?.withColor(Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) => Container(width: 1, color: Colors.white.withValues(alpha: 0.15));
}

class _ZoneButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ZoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            'home.today_hunting_set_zone'.tr(),
            style: context.textStyles.labelLarge?.withColor(LightModeColors.lightForest).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
