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
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/domain/hunting_preferences.dart';

class HuntingZonePage extends ConsumerStatefulWidget {
  const HuntingZonePage({super.key});

  @override
  ConsumerState<HuntingZonePage> createState() => _HuntingZonePageState();
}

class _HuntingZonePageState extends ConsumerState<HuntingZonePage> {
  int step = 0;
  SupportedCountry? country;

  @override
  void initState() {
    super.initState();
    final code = ref.read(userSettingsProvider).countryCode;
    country = SupportedCountry.values.where((item) => item.code == code).firstOrNull;
  }

  void next() => setState(() => step += 1);
  void back() => step == 0 ? context.go(AppRoutes.hunting) : setState(() => step -= 1);

  void save() {
    ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: country!.code);
    context.go(AppRoutes.hunting);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final content = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: AppSpacing.lg, bottom: isMobile ? 88 : AppSpacing.lg),
          sliver: SliverList.list(
            children: [
              Text('zone.title'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              ZoneStepIndicator(currentStep: step),
              const SizedBox(height: AppSpacing.lg),
              if (step == 0) CountryStep(selected: country, onSelected: (value) => setState(() => country = value)),
              if (step == 1) const RegionStep(),
              if (step == 2) UnitStep(country: country!),
              if (!isMobile) ...[const SizedBox(height: AppSpacing.lg), ZoneActions(step: step, canContinue: country != null, onBack: back, onNext: next, onSave: save)],
            ],
          ),
        ),
      ],
    );
    return PageColumns(
      center: isMobile
          ? Column(
              children: [
                Expanded(child: content),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: Colors.white,
                  child: SafeArea(top: false, child: ZoneActions(step: step, canContinue: country != null, onBack: back, onNext: next, onSave: save)),
                ),
              ],
            )
          : content,
    );
  }
}

class ZoneStepIndicator extends StatelessWidget {
  final int currentStep;

  const ZoneStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 3; index++) ...[
        HBChip(label: '${index + 1}', selected: index == currentStep, onTap: index < currentStep ? () {} : null),
        if (index < 2) const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs), child: Text('·')),
      ],
    ],
  );
}

class CountryStep extends StatelessWidget {
  final SupportedCountry? selected;
  final ValueChanged<SupportedCountry> onSelected;

  const CountryStep({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('zone.country_title'.tr(), style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text('zone.country_subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
        const SizedBox(height: AppSpacing.md),
        HBCard(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: RadioGroup<SupportedCountry>(
            groupValue: selected,
            onChanged: (value) { if (value != null) onSelected(value); },
            child: Column(
              children: [
                for (final item in SupportedCountry.values)
                  RadioListTile<SupportedCountry>(
                    value: item,
                    activeColor: LightModeColors.lightPrimary,
                    title: Text(item.translationKey.tr()),
                    subtitle: Text(item.code, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RegionStep extends StatelessWidget {
  const RegionStep({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('zone.region_title'.tr(), style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.md),
      HBInput(hint: 'zone.search_region'.tr(), prefixIcon: const Icon(Icons.search_rounded)),
      const SizedBox(height: AppSpacing.md),
      HBCard(child: HBEmptyState(icon: Icons.map_outlined, title: 'zone.region_empty_title'.tr(), message: 'zone.region_empty_message'.tr())),
    ],
  );
}

class UnitStep extends StatelessWidget {
  final SupportedCountry country;

  const UnitStep({super.key, required this.country});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(unitTypeFor(country).translationKey.tr(), style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.md),
      HBInput(hint: 'zone.search_unit'.tr(), prefixIcon: const Icon(Icons.search_rounded)),
      const SizedBox(height: AppSpacing.md),
      HBCard(child: HBEmptyState(icon: Icons.location_on_outlined, title: 'zone.unit_empty_title'.tr(), message: 'zone.unit_empty_message'.tr())),
    ],
  );
}

class ZoneActions extends StatelessWidget {
  final int step;
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const ZoneActions({super.key, required this.step, required this.canContinue, required this.onBack, required this.onNext, required this.onSave});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      HBButton.ghost(label: 'common.back'.tr(), onPressed: onBack),
      const Spacer(),
      if (step == 1) HBButton.soft(label: 'zone.skip_now'.tr(), onPressed: onNext),
      if (step == 2) HBButton.primary(label: 'zone.save'.tr(), onPressed: onSave),
      if (step == 0) HBButton.primary(label: 'common.next'.tr(), onPressed: canContinue ? onNext : null),
    ],
  );
}