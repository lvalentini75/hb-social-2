import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';

class HuntingCalendarPage extends ConsumerStatefulWidget {
  const HuntingCalendarPage({super.key});

  @override
  ConsumerState<HuntingCalendarPage> createState() => _HuntingCalendarPageState();
}

class _HuntingCalendarPageState extends ConsumerState<HuntingCalendarPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int viewIndex = 0;

  void changeMonth(int offset) => setState(() => month = DateTime(month.year, month.month + offset));

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final countryName = settings.countryCode == null ? null : 'zone.country_${settings.countryCode!.toLowerCase()}'.tr();
    return PageColumns(
      rail: const HuntingCalendarRail(),
      center: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Text('calendar.title'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                    HBChip(label: countryName ?? 'calendar.set_zone'.tr(), selected: countryName != null, onTap: () => context.go(AppRoutes.huntingZone)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                MonthNavigator(month: month, onPrevious: () => changeMonth(-1), onNext: () => changeMonth(1)),
                const SizedBox(height: AppSpacing.md),
                HBSegmentedTabs(labels: ['calendar.view_species'.tr(), 'calendar.view_date'.tr()], selectedIndex: viewIndex, onChanged: (index) => setState(() => viewIndex = index)),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    HBStatusChip(kind: HBStatusKind.approved, label: 'calendar.status_open'.tr()),
                    HBStatusChip(kind: HBStatusKind.neutral, label: 'calendar.status_closed'.tr()),
                    HBStatusChip(kind: HBStatusKind.pending, label: 'calendar.status_soon'.tr()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                HBCard(
                  child: HBEmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: (settings.countryCode == null ? 'calendar.empty_no_zone_title' : 'calendar.empty_database_title').tr(),
                    message: (settings.countryCode == null ? 'calendar.empty_no_zone_message' : 'calendar.empty_database_message').tr(),
                    action: settings.countryCode == null ? HBButton.primary(label: 'calendar.set_zone'.tr(), onPressed: () => context.go(AppRoutes.huntingZone)) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthNavigator({super.key, required this.month, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      HBButton.icon(icon: Icons.chevron_left_rounded, onPressed: onPrevious),
      SizedBox(width: 220, child: Text(toBeginningOfSentenceCase(DateFormat.yMMMM(context.locale.toString()).format(month)) ?? '', textAlign: TextAlign.center, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
      HBButton.icon(icon: Icons.chevron_right_rounded, onPressed: onNext),
    ],
  );
}

class HuntingCalendarRail extends StatelessWidget {
  const HuntingCalendarRail({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageRailCard(
        label: 'calendar.rail_today'.tr(),
        child: Column(children: [
          CalendarRailRow(label: 'calendar.sunrise'.tr()),
          CalendarRailRow(label: 'calendar.sunset'.tr()),
          CalendarRailRow(label: 'calendar.moon_phase'.tr()),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      PageRailCard(
        label: 'calendar.rail_source'.tr(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('calendar.official_source'.tr(), style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text('calendar.last_update'.tr(namedArgs: {'date': '—'}), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      PageRailCard(label: 'calendar.rail_alerts'.tr(), child: Text('calendar.alerts_empty'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
    ],
  );
}

class CalendarRailRow extends StatelessWidget {
  final String label;

  const CalendarRailRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(children: [Expanded(child: Text(label, style: context.textStyles.bodySmall)), Text('—', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))]),
  );
}