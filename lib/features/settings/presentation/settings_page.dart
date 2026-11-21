import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/app_constants.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/l10n/app_locales.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_country_picker.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/auth/presentation/change_password_dialog.dart';
import 'package:hb_social/features/auth/presentation/mfa_settings_control.dart';
import 'package:hb_social/core/providers/translation_providers.dart';
import 'package:intl/intl.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void showSoon(BuildContext context) => showComingSoonInfo(context, icon: Icons.schedule_rounded, title: 'common.coming_soon_title'.tr(), message: 'settings.coming_soon_message'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final isAuthenticated = ref.watch(authSessionProvider).value != null;
    return PageColumns(
      center: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                sliver: SliverList.list(
                  children: [
                    Text('settings.title'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.lg),
                    SettingsSection(
                      title: 'settings.account_section'.tr(),
                      children: [
                        if (!isAuthenticated)
                          SettingsRow(
                            icon: Icons.person_outline_rounded,
                            title: 'settings.guest_account'.tr(),
                            trailing: HBButton.soft(label: 'login.login_button'.tr(), onPressed: () => context.go(AppRoutes.login), size: HBButtonSize.sm),
                          ),
                        if (isAuthenticated) SettingsRow(icon: Icons.verified_user_outlined, title: 'verification.settings_entry'.tr(), subtitle: 'verification.settings_entry_help'.tr(), onTap: () => context.push(AppRoutes.verification)),
                        if (isAuthenticated) SettingsRow(icon: Icons.key_outlined, title: 'settings.login_methods.title'.tr(), subtitle: 'settings.login_methods.subtitle'.tr(), onTap: () => context.push(AppRoutes.loginMethods)),
                        if (isAuthenticated) SettingsRow(icon: Icons.payments_outlined, title: 'payments.settings_entry'.tr(), subtitle: 'payments.settings_entry_help'.tr(), onTap: () => context.push(AppRoutes.paymentSettings)),
                        if (isAuthenticated) SettingsRow(icon: Icons.credit_card_outlined, title: 'billing.settings_entry'.tr(), subtitle: 'billing.settings_entry_help'.tr(), onTap: () => context.push(AppRoutes.billing)),
                        if (isAuthenticated) SettingsRow(icon: Icons.campaign_outlined, title: 'ads.center.title'.tr(), subtitle: 'ads.center.subtitle'.tr(), onTap: () => context.push(AppRoutes.ads)),
                        if (isAuthenticated) SettingsRow(icon: Icons.rocket_launch_outlined, title: 'boost.my_title'.tr(), subtitle: 'boost.my_subtitle'.tr(), onTap: () => context.push(AppRoutes.boosts)),
                        if (isAuthenticated) SettingsRow(icon: Icons.receipt_long_outlined, title: 'orders.title'.tr(), onTap: () => context.push(AppRoutes.orders)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.preferences_section'.tr(),
                      children: [
                        SettingsChoiceRow(
                          icon: Icons.language_rounded,
                           title: 'settings.language.label'.tr(),
                           options: [for (final locale in AppLocales.supported) SettingsOption(value: locale.languageCode, label: 'settings.language.names.${locale.languageCode}'.tr())],
                          selectedValue: context.locale.languageCode,
                          onSelected: (value) async {
                            final locale = Locale(value);
                            if (isAuthenticated) {
                              try {
                                await ref.read(settingsSaveProvider.notifier).save({'locale': value});
                              } catch (error) {
                                if (context.mounted) _showSaveError(context, error);
                                return;
                              }
                            }
                            if (context.mounted) await context.setLocale(locale);
                            ref.read(userSettingsProvider.notifier).setLocale(locale);
                          },
                        ),
                        if (isAuthenticated) const AutomaticTranslationSettings(),
                        SettingsReferenceChoices(isAuthenticated: isAuthenticated),
                        SettingsChoiceRow(
                          icon: Icons.straighten_rounded,
                          title: 'settings.measurement'.tr(),
                          options: [SettingsOption(value: MeasurementSystem.metric.name, label: 'settings.metric'.tr()), SettingsOption(value: MeasurementSystem.imperial.name, label: 'settings.imperial'.tr())],
                          selectedValue: settings.measurementSystem.name,
                          onSelected: (value) async {
                            final system = MeasurementSystem.values.byName(value);
                            if (isAuthenticated) {
                              try {
                                await ref.read(settingsSaveProvider.notifier).save({'unit_system': system.name});
                              } catch (error) {
                                if (context.mounted) _showSaveError(context, error);
                                return;
                              }
                            }
                            ref.read(userSettingsProvider.notifier).setMeasurementSystem(system);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.hunting_zone_section'.tr(),
                      children: [
                        SettingsRow(
                          icon: Icons.location_on_outlined,
                          title: 'settings.hunting_zone'.tr(),
                          subtitle: settings.countryCode == null ? 'settings.not_set'.tr() : 'hunting.country_region_unset'.tr(namedArgs: {'country': 'zone.country_${settings.countryCode!.toLowerCase()}'.tr()}),
                          onTap: () => context.go(AppRoutes.huntingZone),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.notifications_section'.tr(),
                      children: [SettingsRow(icon: Icons.notifications_none_rounded, title: 'settings.notifications'.tr(), onTap: () => context.push(AppRoutes.notificationSettings))],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.security_section'.tr(),
                      children: [
                        if (isAuthenticated) ...[
                          SettingsRow(icon: Icons.interests_outlined, title: 'settings.interests'.tr(), onTap: () => context.push('${AppRoutes.onboarding}?edit=interests')),
                          const MfaSettingsControl(),
                          SettingsRow(icon: Icons.password_rounded, title: 'auth.password_change.title'.tr(), onTap: () => showDialog<void>(context: context, builder: (_) => const ChangePasswordDialog())),
                        ],
                        SettingsRow(icon: Icons.shield_outlined, title: 'settings.privacy_security'.tr(), onTap: () => context.push(isAuthenticated ? AppRoutes.privacySecurity : AppRoutes.login)),
                        SettingsRow(icon: Icons.support_agent_outlined, title: 'support.settings_entry'.tr(), subtitle: 'support.settings_help'.tr(), onTap: () => context.push(isAuthenticated ? AppRoutes.support : AppRoutes.login)),
                        SettingsRow(icon: Icons.download_outlined, title: 'download.title'.tr(), onTap: () => context.push(AppRoutes.download)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.info_section'.tr(),
                      children: [
                        const SettingsRow(icon: Icons.info_outline_rounded, title: 'settings.version', subtitle: AppConstants.appVersion, translateTitle: true),
                        SettingsRow(icon: Icons.gavel_outlined, title: 'legal.information.title'.tr(), onTap: () => context.push(AppRoutes.legalInformation)),
                        SettingsRow(icon: Icons.description_outlined, title: 'settings.terms'.tr(), onTap: () => context.push('/legal/terms')),
                        SettingsRow(icon: Icons.lock_outline_rounded, title: 'settings.privacy'.tr(), onTap: () => context.push('/legal/privacy')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSaveError(BuildContext context, Object error) {
    final key = error is AppException ? error.messageKey : 'settings.save_error';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));
  }
}

class AutomaticTranslationSettings extends ConsumerWidget {
  const AutomaticTranslationSettings({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(translationUsageProvider);
    final settings = ref.watch(userSettingsProvider);
    return usage.when(
      loading: () => const SettingsChoiceSkeleton(),
      error: (_, __) => SettingsRow(icon: Icons.translate_rounded, title: 'translate.unavailable'.tr()),
      data: (value) => SettingsRow(
        icon: Icons.translate_rounded,
        title: 'settings.language.auto_title'.tr(),
        subtitle: value.enabled ? '${'settings.language.usage'.tr(namedArgs: {'today': NumberFormat.decimalPattern(context.locale.toString()).format(value.todayCharacters), 'limit': NumberFormat.decimalPattern(context.locale.toString()).format(value.dailyLimit)})}\n${'settings.language.deepl'.tr()}' : 'translate.unavailable'.tr(),
        trailing: value.enabled ? Switch(value: settings.autoTranslate, onChanged: (enabled) async {
          await ref.read(userSettingsRepositoryProvider).updateMine(autoTranslate: enabled);
          ref.read(userSettingsProvider.notifier).setAutoTranslate(enabled);
          ref.invalidate(translationUsageProvider);
        }) : null,
      ),
    );
  }
}

/// Country, region and currency choices loaded from Supabase reference tables.
class SettingsReferenceChoices extends ConsumerWidget {
  final bool isAuthenticated;

  const SettingsReferenceChoices({super.key, required this.isAuthenticated});

  Future<bool> _save(BuildContext context, WidgetRef ref, Map<String, dynamic> values) async {
    if (!isAuthenticated) return true;
    try {
      await ref.read(settingsSaveProvider.notifier).save(values);
      return true;
    } catch (error) {
      if (context.mounted) SettingsPage._showSaveError(context, error);
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final countries = ref.watch(countriesProvider);
    final currencies = ref.watch(currenciesProvider);
    final selectedCountry = countries.value?.where((item) => item.code == settings.countryCode).firstOrNull;
    final regions = selectedCountry?.hasRegions == true ? ref.watch(regionsProvider(settings.countryCode!)) : null;
    return Column(
      children: [
        countries.when(
          loading: () => const SettingsChoiceSkeleton(),
          error: (error, stackTrace) => SettingsReferenceError(onRetry: () => ref.invalidate(countriesProvider)),
          data: (_) => Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.public_rounded, size: 22, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.md), Text('settings.country'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))]), const SizedBox(height: AppSpacing.sm), HBCountryPicker(value: settings.countryCode, onChanged: (country) => _changeCountry(context, ref, country))])),
        ),
        if (regions != null)
          regions.when(
            loading: () => const SettingsChoiceSkeleton(),
            error: (error, stackTrace) => SettingsReferenceError(onRetry: () => ref.invalidate(regionsProvider(settings.countryCode!))),
            data: (items) => SettingsChoiceRow(
              icon: Icons.location_on_outlined,
              title: items.isEmpty ? 'settings.region'.tr() : 'settings.region_kind'.tr(namedArgs: {'kind': 'hunting.region_kind.${items.first.kind}'.tr()}),
              options: [for (final item in items) SettingsOption(value: item.id, label: item.name)],
              selectedValue: settings.regionId ?? '',
              onSelected: (value) async {
                if (!await _save(context, ref, {'home_region_id': value})) return;
                ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: settings.countryCode!, regionId: value);
              },
            ),
          ),
        if (settings.countryCode == 'IT') MunicipalitySettingsField(isAuthenticated: isAuthenticated),
        if (settings.regionId != null) HuntingUnitSettingsField(isAuthenticated: isAuthenticated),
        currencies.when(
          loading: () => const SettingsChoiceSkeleton(),
          error: (error, stackTrace) => SettingsReferenceError(onRetry: () => ref.invalidate(currenciesProvider)),
          data: (items) => CurrencySettingsRow(items: items, selectedCode: settings.currencyCode, onSelected: (value) async { if (!await _save(context, ref, {'currency_code': value})) return; ref.read(userSettingsProvider.notifier).setCurrency(value); }),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md), child: Text('marketplace.settings_currency_note'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
      ],
    );
  }

  Future<void> _changeCountry(BuildContext context, WidgetRef ref, ReferenceCountry country) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: Text('country.change_title'.tr()),
      content: Text('country.change_message'.tr(namedArgs: {'currency': country.defaultCurrency, 'units': 'settings.${country.unitSystem}'.tr()})),
      actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'common.confirm'.tr(), onPressed: () => dialog.pop(true))],
    )) ?? false;
    if (!confirmed) return;
    try {
      await ref.read(authRepositoryProvider).completeProfile(countryCode: country.code);
      ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: country.code);
      ref.read(userSettingsProvider.notifier).setCurrency(country.defaultCurrency);
      ref.read(userSettingsProvider.notifier).setMeasurementSystem(country.unitSystem == 'imperial' ? MeasurementSystem.imperial : MeasurementSystem.metric);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(privateUserSettingsProvider);
    } catch (error) { if (context.mounted) SettingsPage._showSaveError(context, error); }
  }
}

class CurrencySettingsRow extends StatelessWidget {
  final List<ReferenceCurrency> items;
  final String selectedCode;
  final ValueChanged<String> onSelected;
  const CurrencySettingsRow({super.key, required this.items, required this.selectedCode, required this.onSelected});

  @override Widget build(BuildContext context) {
    final latest = items.map((item) => item.rateValidOn).whereType<DateTime>().fold<DateTime?>(null, (current, value) => current == null || value.isAfter(current) ? value : current);
    return SettingsRow(
      icon: Icons.payments_outlined,
      title: 'settings.currency'.tr(),
      subtitle: latest == null ? 'currency.rates_unavailable'.tr() : 'currency.updated'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).format(latest)}),
      trailing: Text(selectedCode),
      onTap: () => showDialog<void>(context: context, builder: (dialog) => AlertDialog(
        title: Text('currency.title'.tr()),
        content: SizedBox(width: 460, child: ListView(shrinkWrap: true, children: [
          for (final item in items) ListTile(enabled: item.isAvailable, title: Text('${item.code} · ${item.name}'), subtitle: Text(item.isAvailable ? item.symbol : 'currency.unavailable'.tr()), trailing: item.code == selectedCode ? const Icon(Icons.check_circle, color: LightModeColors.bosco) : null, onTap: item.isAvailable ? () { onSelected(item.code); dialog.pop(); } : null),
          if (latest != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('currency.updated'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).format(latest)}))),
        ])),
        actions: [HBButton.ghost(label: 'common.close'.tr(), onPressed: () => dialog.pop())],
      )),
    );
  }
}

class MunicipalitySettingsField extends ConsumerStatefulWidget {
  final bool isAuthenticated;
  const MunicipalitySettingsField({super.key, required this.isAuthenticated});
  @override
  ConsumerState<MunicipalitySettingsField> createState() => _MunicipalitySettingsFieldState();
}

class _MunicipalitySettingsFieldState extends ConsumerState<MunicipalitySettingsField> {
  final controller = TextEditingController();
  String? loadedId;
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  Future<void> select(Municipality municipality) async {
    if (widget.isAuthenticated) await ref.read(settingsSaveProvider.notifier).save({'home_municipality_id': municipality.id, 'home_region_id': municipality.regionId});
    ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: 'IT', regionId: municipality.regionId, municipalityId: municipality.id);
  }

  Future<void> remove() async {
    if (widget.isAuthenticated) await ref.read(settingsSaveProvider.notifier).save({'home_municipality_id': null});
    final settings = ref.read(userSettingsProvider);
    ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: settings.countryCode!, regionId: settings.regionId, unitId: settings.unitId);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final municipality = settings.municipalityId == null ? null : ref.watch(municipalityProvider(settings.municipalityId!));
    municipality?.whenData((value) { if (value != null && loadedId != value.id) { loadedId = value.id; controller.text = value.compactName; } });
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.location_city_outlined, size: 22, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.md), Expanded(child: Text('settings.municipality'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))), if (settings.municipalityId != null) HBButton.ghost(label: 'common.remove'.tr(), onPressed: remove, size: HBButtonSize.sm)]),
      const SizedBox(height: AppSpacing.sm),
      HBPlaceField<Municipality>(controller: controller, hint: 'settings.municipality_hint'.tr(), search: (query) async => [for (final item in await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: 'IT')) HBPlaceSuggestion(value: item, title: item.compactName, subtitle: [if (item.nameAlt?.isNotEmpty == true) item.nameAlt!, item.regionName].join(' · '))], onSelected: select),
    ]));
  }
}

class HuntingUnitSettingsField extends ConsumerWidget {
  final bool isAuthenticated;
  const HuntingUnitSettingsField({super.key, required this.isAuthenticated});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final units = ref.watch(huntingUnitsByRegionProvider(settings.regionId!));
    final types = settings.countryCode == null ? const AsyncData<List<HuntingUnitTypeInfo>>([]) : ref.watch(unitTypesProvider(settings.countryCode!));
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12), child: units.when(
      loading: () => const SettingsChoiceSkeleton(),
      error: (_, __) => SettingsReferenceError(onRetry: () => ref.invalidate(huntingUnitsByRegionProvider(settings.regionId!))),
      data: (items) {
        if (items.isEmpty) return HBEmptyState(icon: Icons.location_on_outlined, title: 'hunting.units_empty'.tr(namedArgs: {'region': settings.regionId!}), message: 'hunting.units_empty_forum'.tr());
        final typeNames = {for (final type in types.value ?? const <HuntingUnitTypeInfo>[]) type.code: type.nameKey.tr()};
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('settings.hunting_unit'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: AppSpacing.sm), HBSelect<String>(value: settings.unitId, allowClear: true, placeholder: 'settings.hunting_unit'.tr(), options: [for (final item in items) HBSelectOption(value: item.id, label: item.name, groupLabel: typeNames[item.unitType] ?? 'hunting.unit_type.${item.unitType}'.tr())], onChanged: (value) async { if (isAuthenticated) await ref.read(settingsSaveProvider.notifier).save({'hunting_unit_id': value}); ref.read(userSettingsProvider.notifier).setHuntingZone(countryCode: settings.countryCode!, regionId: settings.regionId, unitId: value, municipalityId: settings.municipalityId); })]);
      },
    ));
  }
}

class SettingsChoiceSkeleton extends StatelessWidget {
  const SettingsChoiceSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: HBSkeleton(height: 72));
}

class SettingsReferenceError extends StatelessWidget {
  final VoidCallback onRetry;

  const SettingsReferenceError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(children: [Expanded(child: Text('settings.reference_error'.tr(), style: context.textStyles.bodySmall)), HBButton.ghost(label: 'common.retry'.tr(), onPressed: onRetry, size: HBButtonSize.sm)]),
  );
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm), child: Text(title.toUpperCase(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4))),
      HBCard(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Column(children: children)),
    ],
  );
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool translateTitle;

  const SettingsRow({super.key, required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.translateTitle = false});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: LightModeColors.lightOnSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(translateTitle ? title.tr() : title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null) Text(subtitle!, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
                ],
              ),
            ),
            if (trailing != null) trailing! else if (onTap != null) const Icon(Icons.chevron_right_rounded, color: LightModeColors.lightTextTertiary),
          ],
        ),
      ),
    ),
  );
}

class SettingsOption {
  final String value;
  final String label;

  const SettingsOption({required this.value, required this.label});
}

class SettingsChoiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<SettingsOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const SettingsChoiceRow({super.key, required this.icon, required this.title, required this.options, required this.selectedValue, required this.onSelected});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 22, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.md), Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))]),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final option in options) HBChip(label: option.label, selected: option.value == selectedValue, onTap: () => onSelected(option.value))]),
      ],
    ),
  );
}