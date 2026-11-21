import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';

class StepRegion extends ConsumerWidget {
  final String countryCode;
  final String? regionId;
  final ValueChanged<String> onChanged;

  const StepRegion({super.key, required this.countryCode, required this.regionId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(regionsProvider(countryCode)).when(
    loading: () => const LinearProgressIndicator(),
    error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'onboarding.region_error_title'.tr(), message: 'onboarding.region_error_message'.tr()),
    data: (regions) => HBFormField(label: 'onboarding.location_region_label'.tr(), child: HBSelect<String>(value: regions.any((item) => item.id == regionId) ? regionId : null, options: [for (final region in regions) HBSelectOption(value: region.id, label: region.name)], onChanged: (value) { if (value != null) onChanged(value); })),
  );
}