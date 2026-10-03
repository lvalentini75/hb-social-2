import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/home/presentation/widgets/today_hunting_card.dart';
import 'package:hb_social/features/hunting/domain/hunting_preferences.dart';

class HuntingHubPage extends StatelessWidget {
  const HuntingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageColumns(
      rail: const HuntingHubRail(),
      center: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                Text('hunting.title'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text('hunting.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(builder: (context, constraints) => TodayHuntingCard(isWide: constraints.maxWidth >= 700)),
                const SizedBox(height: AppSpacing.lg),
                const HuntingToolsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HuntingToolsGrid extends StatelessWidget {
  const HuntingToolsGrid({super.key});

  static const tools = [
    HuntingShortcutDefinition(icon: Icons.calendar_month_outlined, titleKey: 'hunting.calendar_title', descriptionKey: 'hunting.calendar_description', statusKey: 'hunting.status_zone_unset', path: AppRoutes.huntingCalendar),
    HuntingShortcutDefinition(icon: Icons.menu_book_outlined, titleKey: 'hunting.diary_title', descriptionKey: 'hunting.diary_description', statusKey: 'hunting.status_no_outings', path: AppRoutes.huntingDiary),
    HuntingShortcutDefinition(icon: Icons.map_outlined, titleKey: 'hunting.map_title', descriptionKey: 'hunting.map_description', statusKey: 'hunting.status_set_zone_units', path: AppRoutes.huntingMap),
    HuntingShortcutDefinition(icon: Icons.pets_outlined, titleKey: 'hunting.dogs_title', descriptionKey: 'hunting.dogs_description', statusKey: 'hunting.status_no_dogs', path: AppRoutes.huntingDogs),
    HuntingShortcutDefinition(icon: Icons.visibility_outlined, titleKey: 'hunting.sightings_title', descriptionKey: 'hunting.sightings_description', statusKey: 'common.coming_soon_title', path: AppRoutes.huntingSightings),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final tool in tools) SizedBox(width: width, child: HuntingToolCard(tool: tool))],
        );
      },
    );
  }
}

class HuntingToolCard extends StatelessWidget {
  final HuntingShortcutDefinition tool;

  const HuntingToolCard({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      radius: AppRadius.md,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.go(tool.path),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 48, height: 48, decoration: const BoxDecoration(color: LightModeColors.lightPrimarySoft, shape: BoxShape.circle), child: Icon(tool.icon, size: 28, color: LightModeColors.lightPrimary)),
                const SizedBox(height: AppSpacing.md),
                Text(tool.titleKey.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(tool.descriptionKey.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Text(tool.statusKey.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HuntingHubRail extends ConsumerWidget {
  const HuntingHubRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    return Column(
      children: [
        PageRailCard(
          label: 'hunting.rail_zone_title'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.countryCode == null ? 'hunting.status_zone_unset'.tr() : 'hunting.country_region_unset'.tr(namedArgs: {'country': 'zone.country_${settings.countryCode!.toLowerCase()}'.tr()}),
                style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              HBButton.soft(label: 'home.today_hunting_set_zone'.tr(), onPressed: () => context.go(AppRoutes.huntingZone)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PageRailCard(label: 'hunting.rail_season_title'.tr(), child: Text('home.season_empty'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
      ],
    );
  }
}