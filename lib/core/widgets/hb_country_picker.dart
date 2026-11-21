import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/locale_resolver.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';

/// The single country selector used across app and console flows.
class HBCountryPicker extends ConsumerWidget {
  final String? value;
  final ValueChanged<ReferenceCountry> onChanged;
  final bool enabled;

  const HBCountryPicker({super.key, this.value, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final selected = countries.value?.where((item) => item.code == value).firstOrNull;
    return Semantics(
      button: true,
      label: 'country.open'.tr(),
      child: InkWell(
        onTap: enabled ? () async { final result = await show(context); if (result != null) onChanged(result); } : null,
        borderRadius: BorderRadius.circular(AppRadius.inner),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(color: LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.inner), border: Border.all(color: LightModeColors.border)),
          child: Row(children: [Text(selected?.flag ?? '', style: const TextStyle(fontSize: 22)), if (selected != null) const SizedBox(width: AppSpacing.sm), Expanded(child: Text(selected?.name ?? 'country.choose'.tr(), overflow: TextOverflow.ellipsis)), const Icon(Icons.keyboard_arrow_down_rounded)]),
        ),
      ),
    );
  }

  Future<ReferenceCountry?> show(BuildContext context) {
    final content = CountryPickerPanel(selectedCode: value);
    if (MediaQuery.sizeOf(context).width < 700) {
      return showModalBottomSheet<ReferenceCountry>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: 1, child: content));
    }
    return showDialog<ReferenceCountry>(context: context, builder: (_) => Dialog(child: SizedBox(width: 560, height: 680, child: content)));
  }
}

class CountryPickerPanel extends ConsumerStatefulWidget {
  final String? selectedCode;
  const CountryPickerPanel({super.key, this.selectedCode});
  @override ConsumerState<CountryPickerPanel> createState() => _CountryPickerPanelState();
}

class _CountryPickerPanelState extends ConsumerState<CountryPickerPanel> {
  final search = TextEditingController();
  @override void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text('country.title'.tr(), style: context.textStyles.titleLarge)), HBButton.icon(icon: Icons.close, tooltip: 'common.close'.tr(), onPressed: () => context.pop())]),
        const SizedBox(height: AppSpacing.md),
        HBInput(controller: search, hint: 'country.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (_) => setState(() {})),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: countries.when(
          loading: () => ListView(children: const [HBSkeleton(height: 56), SizedBox(height: 8), HBSkeleton(height: 56), SizedBox(height: 8), HBSkeleton(height: 56)]),
          error: (_, __) => HBEmptyState(icon: Icons.public_off_outlined, title: 'country.error_title'.tr(), message: 'country.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(countriesProvider))),
          data: _list,
        )),
      ]),
    );
  }

  Widget _list(List<ReferenceCountry> countries) {
    final query = _normalize(search.text.trim());
    final filtered = query.isEmpty ? countries : countries.where((item) => _normalize('${item.name} ${item.nativeName} ${item.code}').contains(query)).toList();
    if (filtered.isEmpty) return HBEmptyState(icon: Icons.search_off_rounded, title: 'country.empty_title'.tr(), message: 'country.empty_message'.tr());
    final deviceCode = LocaleResolver.fromDevice().deviceCountryCode;
    final suggested = filtered.where((item) => item.code == deviceCode && item.code != widget.selectedCode).firstOrNull;
    final others = filtered.where((item) => item.code != suggested?.code).toList();
    return ListView(children: [
      if (suggested != null) ...[Text('country.suggested'.tr(), style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w700)), CountryPickerRow(country: suggested), const Divider()],
      for (final country in others) CountryPickerRow(country: country, selected: country.code == widget.selectedCode),
    ]);
  }

  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp('[àáâãäå]'), 'a').replaceAll(RegExp('[çč]'), 'c').replaceAll(RegExp('[èéêë]'), 'e').replaceAll(RegExp('[ìíîï]'), 'i').replaceAll(RegExp('[ñ]'), 'n').replaceAll(RegExp('[òóôõö]'), 'o').replaceAll(RegExp('[ùúûü]'), 'u').replaceAll(RegExp('[ýÿ]'), 'y').replaceAll('ß', 'ss');
}

class CountryPickerRow extends StatelessWidget {
  final ReferenceCountry country;
  final bool selected;
  const CountryPickerRow({super.key, required this.country, this.selected = false});
  @override Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
    title: Text(country.name),
    subtitle: country.nativeName.isEmpty || country.nativeName == country.name ? null : Text(country.nativeName),
    trailing: selected ? const Icon(Icons.check_circle, color: LightModeColors.bosco) : Text(country.code),
    onTap: () => context.pop(country),
  );
}