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
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void showSoon(BuildContext context) => showComingSoonInfo(context, icon: Icons.schedule_rounded, title: 'common.coming_soon_title'.tr(), message: 'settings.coming_soon_message'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final isAuthenticated = ref.watch(authStateProvider).isAuthenticated;
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.preferences_section'.tr(),
                      children: [
                        SettingsChoiceRow(
                          icon: Icons.language_rounded,
                          title: 'settings.language'.tr(),
                          options: [for (final locale in AppLocales.supported) SettingsOption(value: locale.languageCode, label: 'language.${locale.languageCode}'.tr())],
                          selectedValue: context.locale.languageCode,
                          onSelected: (value) {
                            final locale = Locale(value);
                            context.setLocale(locale);
                            ref.read(userSettingsProvider.notifier).setLocale(locale);
                          },
                        ),
                        SettingsChoiceRow(
                          icon: Icons.payments_outlined,
                          title: 'settings.currency'.tr(),
                          options: const [SettingsOption(value: 'EUR', label: 'EUR'), SettingsOption(value: 'GBP', label: 'GBP'), SettingsOption(value: 'CHF', label: 'CHF'), SettingsOption(value: 'USD', label: 'USD')],
                          selectedValue: settings.currencyCode,
                          onSelected: ref.read(userSettingsProvider.notifier).setCurrency,
                        ),
                        SettingsChoiceRow(
                          icon: Icons.straighten_rounded,
                          title: 'settings.measurement'.tr(),
                          options: [SettingsOption(value: MeasurementSystem.metric.name, label: 'settings.metric'.tr()), SettingsOption(value: MeasurementSystem.imperial.name, label: 'settings.imperial'.tr())],
                          selectedValue: settings.measurementSystem.name,
                          onSelected: (value) => ref.read(userSettingsProvider.notifier).setMeasurementSystem(MeasurementSystem.values.byName(value)),
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
                      children: [SettingsRow(icon: Icons.notifications_none_rounded, title: 'settings.notifications'.tr(), onTap: () => context.go(AppRoutes.notifications))],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.security_section'.tr(),
                      children: [
                        SettingsRow(icon: Icons.shield_outlined, title: 'settings.privacy_security'.tr(), onTap: () => showSoon(context)),
                        SettingsRow(icon: Icons.download_outlined, title: 'settings.data_download'.tr(), onTap: () => showSoon(context)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsSection(
                      title: 'settings.info_section'.tr(),
                      children: [
                        const SettingsRow(icon: Icons.info_outline_rounded, title: 'settings.version', subtitle: AppConstants.appVersion, translateTitle: true),
                        SettingsRow(icon: Icons.description_outlined, title: 'settings.terms'.tr(), onTap: () => showSoon(context)),
                        SettingsRow(icon: Icons.lock_outline_rounded, title: 'settings.privacy'.tr(), onTap: () => showSoon(context)),
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