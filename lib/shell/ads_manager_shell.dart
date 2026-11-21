import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

class AdsManagerShell extends ConsumerWidget {
  final Widget child;
  const AdsManagerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    return Scaffold(
      backgroundColor: LightModeColors.lightBackground,
      body: SafeArea(bottom: false, child: wide ? Row(children: [const AdsManagerRail(), Expanded(child: Column(children: [const AdsManagerTopBar(), Expanded(child: child)]))]) : Column(children: [const AdsManagerMobileTopBar(), Expanded(child: child), const AdsManagerBottomBar()])),
    );
  }
}

class AdsManagerRail extends ConsumerWidget {
  const AdsManagerRail({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final accountId = _accountId(path);
    final items = <({IconData icon, String key, String route})>[
      (icon: Icons.space_dashboard_outlined, key: 'overview', route: AppRoutes.ads),
      (icon: Icons.rocket_launch_outlined, key: 'boosts', route: AppRoutes.boosts),
      if (accountId != null) ...[
        (icon: Icons.campaign_outlined, key: 'campaigns', route: AppRoutes.adAccountCampaignsPath(accountId)),
        (icon: Icons.groups_outlined, key: 'audiences', route: AppRoutes.adAccountSectionPath(accountId, 'audiences')),
        (icon: Icons.auto_awesome_motion_outlined, key: 'creatives', route: AppRoutes.adAccountSectionPath(accountId, 'creatives')),
        (icon: Icons.credit_card_outlined, key: 'billing', route: AppRoutes.adAccountSectionPath(accountId, 'billing')),
        (icon: Icons.insights_outlined, key: 'report', route: AppRoutes.adAccountSectionPath(accountId, 'report')),
      ],
    ];
    return Container(width: 92, color: LightModeColors.night, child: Column(children: [
      SizedBox(height: 64, child: HBButton.icon(icon: Icons.landscape_rounded, tooltip: 'ads_manager.back_home'.tr(), onPressed: () => context.go(AppRoutes.home), foregroundColor: LightModeColors.adminSidebarText)),
      for (final item in items) AdsManagerRailItem(icon: item.icon, label: item.key == 'boosts' ? 'boost.my_title'.tr() : 'ads_manager.nav.${item.key}'.tr(), active: item.route == AppRoutes.ads ? path == AppRoutes.ads : path.startsWith(item.route), onTap: () => context.go(item.route)),
      const Spacer(),
      if (accountId != null) AdsManagerRailItem(icon: Icons.settings_outlined, label: 'ads_manager.nav.settings'.tr(), active: path.endsWith('/settings'), onTap: () => context.go(AppRoutes.adAccountSectionPath(accountId, 'settings'))),
      const SizedBox(height: AppSpacing.sm),
    ]));
  }
}

class AdsManagerRailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const AdsManagerRailItem({super.key, required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: InkWell(borderRadius: BorderRadius.circular(AppRadius.sm), onTap: onTap, child: AnimatedContainer(duration: AppMotion.of(context).fast, width: 76, height: 58, decoration: BoxDecoration(color: active ? LightModeColors.bosco : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 22, color: active ? LightModeColors.lightSurface : LightModeColors.adminSidebarText), const SizedBox(height: 3), Text(label, maxLines: 1, softWrap: false, style: context.textStyles.labelSmall?.copyWith(fontSize: 10.5, color: active ? LightModeColors.lightSurface : LightModeColors.adminSidebarText))]))));
}

class AdsManagerTopBar extends ConsumerWidget {
  const AdsManagerTopBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final accountId = _accountId(path);
    final accounts = ref.watch(adAccountsProvider).value ?? const <AdAccount>[];
    final selected = accounts.where((item) => item.id == accountId).firstOrNull;
    final profile = ref.watch(currentProfileProvider).value;
    return Container(height: 64, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), color: LightModeColors.lightSurface, child: Row(children: [
       Text('ads_manager.title'.tr(), style: context.textStyles.headlineMedium), const SizedBox(width: AppSpacing.xl),
      AdsAccountSelector(accounts: accounts, selected: selected), const Spacer(),
      SizedBox(width: 260, child: HBInput(search: true, hint: 'ads_manager.search'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: (value) => ref.read(adsManagerSearchProvider.notifier).state = value)), const SizedBox(width: AppSpacing.sm),
      const AdsDateSelector(compact: false), const SizedBox(width: AppSpacing.xs),
      HBButton.icon(icon: Icons.notifications_none_rounded, tooltip: 'nav.notifications'.tr(), onPressed: () => context.go(AppRoutes.notifications)),
      const SizedBox(width: AppSpacing.xs), HBAvatar(size: 36, name: profile?.displayName, imageUrl: profile?.avatarUrl),
    ]));
  }
}

class AdsAccountSelector extends StatelessWidget {
  final List<AdAccount> accounts;
  final AdAccount? selected;
  const AdsAccountSelector({super.key, required this.accounts, this.selected});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(onSelected: (id) => context.go(id == 'new' ? '${AppRoutes.ads}?create=1' : AppRoutes.adAccountCampaignsPath(id)), itemBuilder: (_) => [for (final account in accounts) PopupMenuItem(value: account.id, child: Row(children: [AdsAccountStatusDot(account: account), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(account.name)), if (account.kind == 'personal') HBChip(label: 'boost.personal'.tr(), tag: true)])), const PopupMenuDivider(), PopupMenuItem(value: 'new', child: Row(children: [const Icon(Icons.add_rounded), const SizedBox(width: AppSpacing.sm), Text('ads_manager.new_account'.tr())]))], child: Container(height: 42, constraints: const BoxConstraints(maxWidth: 250), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Row(mainAxisSize: MainAxisSize.min, children: [HBAvatar(size: 30, name: selected?.name), const SizedBox(width: AppSpacing.sm), if (selected != null) AdsAccountStatusDot(account: selected!), const SizedBox(width: AppSpacing.xs), Flexible(child: Text(selected?.name ?? 'ads_manager.all_accounts'.tr(), overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium)), if (selected?.kind == 'personal') HBChip(label: 'boost.personal'.tr(), tag: true), const Icon(Icons.arrow_drop_down_rounded)])));
}

class AdsAccountStatusDot extends StatelessWidget {
  final AdAccount account;
  const AdsAccountStatusDot({super.key, required this.account});
  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: account.status.name == 'suspended' ? LightModeColors.lightError : account.billingStatus == 'ok' ? LightModeColors.lightSuccess : LightModeColors.lightWarning));
}

class AdsDateSelector extends ConsumerWidget {
  final bool compact;
  const AdsDateSelector({super.key, required this.compact});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(adsDatePresetProvider);
    final range = value.range;
    final label = compact ? 'ads_manager.period.short.${value.name}'.tr() : 'ads_manager.period.value'.tr(namedArgs: {'preset': 'ads_manager.period.${value.name}'.tr(), 'from': DateFormat.MMMd(context.locale.toString()).format(range.from), 'to': DateFormat.MMMd(context.locale.toString()).format(range.to.subtract(const Duration(days: 1)))});
    return PopupMenuButton<AdsDatePreset>(onSelected: (item) => ref.read(adsDatePresetProvider.notifier).state = item, itemBuilder: (_) => [for (final item in AdsDatePreset.values) PopupMenuItem(value: item, child: Text('ads_manager.period.${item.name}'.tr()))], child: Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: context.textStyles.labelMedium), const SizedBox(width: AppSpacing.xs), const Icon(Icons.arrow_drop_down_rounded)])));
  }
}

class AdsManagerMobileTopBar extends StatelessWidget {
  const AdsManagerMobileTopBar({super.key});
  @override
  Widget build(BuildContext context) => Container(color: LightModeColors.lightSurface, padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm), child: Column(children: [SizedBox(height: 48, child: Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, tooltip: 'common.back'.tr(), onPressed: () => context.go(AppRoutes.home)), Expanded(child: Text('ads_manager.title'.tr(), style: context.textStyles.headlineLarge)), HBButton.icon(icon: Icons.notifications_none_rounded, tooltip: 'nav.notifications'.tr(), onPressed: () => context.go(AppRoutes.notifications))])), Consumer(builder: (context, ref, _) { final path = GoRouterState.of(context).uri.path; final accounts = ref.watch(adAccountsProvider).value ?? const <AdAccount>[]; final id = _accountId(path); return Row(children: [Expanded(child: AdsAccountSelector(accounts: accounts, selected: accounts.where((item) => item.id == id).firstOrNull)), const SizedBox(width: AppSpacing.sm), const AdsDateSelector(compact: true)]); })]));
}

class AdsManagerBottomBar extends StatelessWidget {
  const AdsManagerBottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final id = _accountId(path);
    final items = <({IconData icon, String key, String route})>[(icon: Icons.space_dashboard_outlined, key: 'overview', route: AppRoutes.ads), if (id != null) (icon: Icons.campaign_outlined, key: 'campaigns', route: AppRoutes.adAccountCampaignsPath(id)), if (id != null) (icon: Icons.groups_outlined, key: 'audiences', route: AppRoutes.adAccountSectionPath(id, 'audiences')), if (id != null) (icon: Icons.auto_awesome_motion_outlined, key: 'creatives', route: AppRoutes.adAccountSectionPath(id, 'creatives')), if (id != null) (icon: Icons.credit_card_outlined, key: 'billing', route: AppRoutes.adAccountSectionPath(id, 'billing'))];
    return Container(height: 84, color: LightModeColors.night, child: Row(children: [for (final item in items) Expanded(child: Builder(builder: (context) { final active = item.route == AppRoutes.ads ? path == AppRoutes.ads : path.startsWith(item.route); return InkWell(onTap: () => context.go(item.route), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, color: active ? LightModeColors.lightSurface : LightModeColors.adminSidebarText), Text('ads_manager.nav.${item.key}'.tr(), overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.copyWith(color: active ? LightModeColors.lightSurface : LightModeColors.adminSidebarText))])); }))]));
  }
}

String? _accountId(String path) {
  final parts = Uri.parse(path).pathSegments;
  if (parts.length < 2 || parts.first != 'ads' || parts[1] == 'campaigns' || parts[1] == 'boosts') return null;
  return parts[1];
}