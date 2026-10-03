import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/onboarding/domain/hunting_country.dart';

/// Onboarding step 1: country (always) and region (only when the selected
/// country has a region list, i.e. Italy).
class StepLocation extends StatelessWidget {
  final String? countryCode;
  final String? regionCode;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onRegionChanged;

  const StepLocation({
    super.key,
    required this.countryCode,
    required this.regionCode,
    required this.onCountryChanged,
    required this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCountry = huntingCountries.where((c) => c.code == countryCode).toList();
    final regionCodes = selectedCountry.isNotEmpty ? selectedCountry.first.regionCodes : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('onboarding.location_country_label'.tr(), style: context.textStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        _PickerField(
          value: countryCode,
          placeholder: 'onboarding.location_country_label'.tr(),
          items: huntingCountries.map((c) => DropdownMenuItem(value: c.code, child: Text(c.translationKey.tr()))).toList(),
          onChanged: (value) {
            if (value != null) onCountryChanged(value);
          },
        ),
        if (regionCodes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('onboarding.location_region_label'.tr(), style: context.textStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          _PickerField(
            value: regionCode,
            placeholder: 'onboarding.location_region_placeholder'.tr(),
            items: regionCodes.map((r) => DropdownMenuItem(value: r, child: Text(regionTranslationKey(r).tr()))).toList(),
            onChanged: (value) {
              if (value != null) onRegionChanged(value);
            },
          ),
        ],
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _PickerField({required this.value, required this.placeholder, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LightModeColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(placeholder, style: context.textStyles.bodyLarge?.withColor(LightModeColors.lightOnSurfaceVariant)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: LightModeColors.lightOnSurfaceVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
