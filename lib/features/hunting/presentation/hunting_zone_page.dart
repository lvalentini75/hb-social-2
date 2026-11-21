import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_country_picker.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';

class HuntingZonePage extends ConsumerStatefulWidget {
  const HuntingZonePage({super.key});
  @override
  ConsumerState<HuntingZonePage> createState() => _HuntingZonePageState();
}

class _HuntingZonePageState extends ConsumerState<HuntingZonePage> {
  String? country;
  String? region;
  String? unit;
  bool initialized = false;
  bool saving = false;

  Future<void> save() async {
    if (country == null) return;
    setState(() => saving = true);
    try {
      if (ref.read(authSessionProvider).value != null) {
        await ref.read(authRepositoryProvider).completeProfile(countryCode: country, regionId: region);
        if (unit != null) await ref.read(settingsSaveProvider.notifier).save({'hunting_unit_id': unit});
      }
      ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: country!, regionId: region, unitId: unit);
      if (mounted) context.go(AppRoutes.hunting);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    if (!initialized) { initialized = true; country = settings.countryCode; region = settings.regionId; unit = settings.unitId; }
    final countries = ref.watch(countriesProvider).value ?? const [];
    final selectedCountry = countries.where((item) => item.code == country).firstOrNull;
    final regions = selectedCountry?.hasRegions == true ? ref.watch(regionsProvider(country!)) : null;
    final units = region == null ? null : ref.watch(huntingUnitsByRegionProvider(region!));
    final types = country == null ? null : ref.watch(unitTypesProvider(country!));
    final typeNames = {for (final item in types?.value ?? const []) item.code: item.nameKey.tr()};
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Text('zone.title'.tr(), style: context.textStyles.headlineSmall),
      const SizedBox(height: AppSpacing.lg),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBFormField(label: 'zone.country_title'.tr(), child: HBCountryPicker(value: country, enabled: !saving, onChanged: (value) => setState(() { country = value.code; region = null; unit = null; }))),
        if (regions != null) ...[const SizedBox(height: AppSpacing.md), HBFormField(label: 'zone.region_title'.tr(), child: HBSelect<String>(value: region, options: [for (final item in regions.value ?? const []) HBSelectOption(value: item.id, label: item.name)], onChanged: saving ? null : (value) => setState(() { region = value; unit = null; })))],
        if (region != null) ...[const SizedBox(height: AppSpacing.md), if ((units?.value ?? const []).isEmpty) HBEmptyState(icon: Icons.location_on_outlined, title: 'hunting.units_empty'.tr(namedArgs: {'region': (regions?.value ?? const []).where((item) => item.id == region).firstOrNull?.name ?? ''}), message: 'hunting.units_empty_forum'.tr()) else HBFormField(label: 'settings.hunting_unit'.tr(), child: HBSelect<String>(value: unit, allowClear: true, options: [for (final item in units!.value!) HBSelectOption(value: item.id, label: item.name, groupLabel: typeNames[item.unitType] ?? 'hunting.unit_type.${item.unitType}'.tr())], onChanged: saving ? null : (value) => setState(() => unit = value)))],
        const SizedBox(height: AppSpacing.lg),
        HBFormActions(primaryLabel: 'zone.save'.tr(), onPrimary: country == null ? null : save, secondaryLabel: 'common.back'.tr(), onSecondary: () => context.pop(), loading: saving),
      ])))),
    ]))]));
  }
}