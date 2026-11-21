import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_module.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String periodKey = 'admin.topbar.period30';
  bool deniedNoticeShown = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final drawerMode = width < 900;
    final compact = width < 1280;
    final location = GoRouterState.of(context).uri.path;
    final slug = location == '/admin' ? '' : location.replaceFirst('/admin/', '').split('/').first;
    final module = adminModuleForSlug(slug) ?? adminModuleForSlug('')!;
    if (!deniedNoticeShown && GoRouterState.of(context).uri.queryParameters['denied'] == '1') {
      deniedNoticeShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.p05.accessDenied'.tr())));
      });
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: LightModeColors.lightBackground,
      drawer: drawerMode ? Drawer(width: 248, backgroundColor: LightModeColors.adminSidebar, child: AdminSidebar(compact: false, currentSlug: slug)) : null,
      body: Row(
        children: [
          if (!drawerMode) AdminSidebar(compact: compact, currentSlug: slug),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  pageTitle: module.titleKey.tr(),
                  periodKey: periodKey,
                  showMenuButton: drawerMode,
                  onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
                  onPeriodChanged: (value) => setState(() => periodKey = value),
                ),
                Expanded(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: widget.child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSidebar extends ConsumerWidget {
  final bool compact;
  final String currentSlug;

  const AdminSidebar({super.key, required this.compact, required this.currentSlug});

  String _path(String slug) => slug.isEmpty ? '/admin' : '/admin/$slug';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(adminAccessProvider).value;
    final profile = ref.watch(currentProfileProvider).value;
    final width = compact ? 64.0 : 248.0;
    final pendingAds = access?.canRead('ad-review') == true ? ref.watch(adReviewQueueProvider('pending')).value?.length ?? 0 : 0;
    final visibleSections = [
      for (final section in adminModuleSections)
        AdminModuleSection(labelKey: section.labelKey, modules: section.modules.where((module) => access?.canRead(module.permissionSlug) ?? false).toList()),
    ].where((section) => section.modules.isNotEmpty);
    return Container(
      width: width,
      color: LightModeColors.night,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.md : AppSpacing.md),
                child: Row(
                  mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const HbLogo(size: 32),
                    if (!compact) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('app.name'.tr(), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('admin.consoleLabel'.tr(), style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
                children: [
                   for (final section in visibleSections) ...[
                    if (!compact) AdminSidebarSectionLabel(label: section.labelKey.tr()),
                    for (final module in section.modules)
                      AdminSidebarTile(
                        compact: compact,
                        icon: module.icon,
                        label: module.titleKey.tr(),
                        selected: module.slug == currentSlug,
                         count: module.slug == 'ads' ? pendingAds : 0,
                        onTap: () {
                           context.go(_path(module.slug));
                          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) context.pop();
                        },
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            AdminSidebarAccountCard(
              compact: compact,
              name: profile?.displayName ?? profile?.username ?? '',
              avatarUrl: profile?.avatarUrl,
              roleName: access?.roleName ?? '',
              mfaEnabled: access?.mfaEnabled ?? false,
              onLogout: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/admin/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSidebarSectionLabel extends StatelessWidget {
  final String label;

  const AdminSidebarSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
    child: Text(label, style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class AdminSidebarTile extends StatelessWidget {
  final bool compact;
  final IconData icon;
  final String label;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const AdminSidebarTile({super.key, required this.compact, required this.icon, required this.label, required this.selected, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: selected ? LightModeColors.bosco : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : AppSpacing.sm),
            child: Row(
              mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : LightModeColors.adminSidebarText),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? Colors.white : LightModeColors.adminSidebarText, fontSize: 14, fontWeight: FontWeight.w500))),
                  if (count > 0) AdminSidebarCountBadge(count: count),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return compact ? Tooltip(message: label, child: tile) : tile;
  }
}

class AdminSidebarCountBadge extends StatelessWidget {
  final int count;

  const AdminSidebarCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: LightModeColors.adminSidebarText.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(count >= 50 ? '50+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class AdminSidebarAccountCard extends StatelessWidget {
  final bool compact;
  final String name;
  final String? avatarUrl;
  final String roleName;
  final bool mfaEnabled;
  final VoidCallback onLogout;

  const AdminSidebarAccountCard({super.key, required this.compact, required this.name, this.avatarUrl, required this.roleName, required this.mfaEnabled, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : AppSpacing.sm),
          child: Row(
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              HBAvatar(size: 36, name: name, imageUrl: avatarUrl),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(children: [Flexible(child: HBStatusChip(kind: _roleKind(roleName), label: _roleKey(roleName).tr())), if (mfaEnabled) Text(' · ${'admin.account.twoFactor'.tr()}', style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 12))]),
                    ],
                  ),
                ),
                const Icon(Icons.logout, size: 18, color: LightModeColors.adminSidebarMuted),
              ],
            ],
          ),
        ),
      ),
    );
    return Tooltip(message: 'auth.logout'.tr(), child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: card));
  }

  String _roleKey(String role) => 'admin.roles.${switch (role) { 'ads_reviewer' => 'adsReviewer', 'hunting_data_editor' => 'huntingDataEditor', _ => role }}';

  HBStatusKind _roleKind(String role) => switch (role) {
    'superadmin' => HBStatusKind.superAdmin,
    'admin' => HBStatusKind.admin,
    'moderator' || 'ads_reviewer' => HBStatusKind.moderator,
    'finance' => HBStatusKind.pending,
    _ => HBStatusKind.approved,
  };
}

class AdminTopBar extends ConsumerWidget {
  final String pageTitle;
  final String periodKey;
  final bool showMenuButton;
  final VoidCallback onMenuPressed;
  final ValueChanged<String> onPeriodChanged;

  const AdminTopBar({super.key, required this.pageTitle, required this.periodKey, required this.showMenuButton, required this.onMenuPressed, required this.onPeriodChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = width >= 1080;
    final showPeriod = width >= 720;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.level1),
      child: Row(
        children: [
          if (showMenuButton) ...[HBButton.icon(icon: Icons.menu, onPressed: onMenuPressed, size: HBButtonSize.sm, backgroundColor: Colors.transparent), const SizedBox(width: AppSpacing.sm)],
          Flexible(child: Text('admin.topbar.breadcrumb'.tr(namedArgs: {'page': pageTitle}), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
          const SizedBox(width: AppSpacing.sm),
          if (Env.isDev)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
              decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('admin.topbar.development'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
            ),
          const Spacer(),
          if (showSearch) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: HBInput(
                hint: 'admin.topbar.searchHint'.tr(),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xs)), child: Text('/', style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)))),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (showPeriod) ...[
            PopupMenuButton<String>(
              onSelected: onPeriodChanged,
              itemBuilder: (context) => ['admin.topbar.period7', 'admin.topbar.period30', 'admin.topbar.period90'].map((key) => PopupMenuItem(value: key, child: Text(key.tr()))).toList(),
              child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 16), const SizedBox(width: 6), Text(periodKey.tr(), style: context.textStyles.labelSmall), const Icon(Icons.arrow_drop_down, size: 18)])),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          HBButton.icon(icon: Icons.notifications_none, onPressed: () {}, size: HBButtonSize.sm),
          const SizedBox(width: AppSpacing.sm),
          if (width >= 560) const AdminQuickActionMenu(),
        ],
      ),
    );
  }
}

class AdminQuickActionMenu extends StatelessWidget {
  const AdminQuickActionMenu({super.key});

  @override
  Widget build(BuildContext context) => MenuAnchor(
    builder: (context, controller, child) => HBButton.primary(label: 'admin.topbar.quickAction'.tr(), icon: Icons.add, onPressed: controller.open, size: HBButtonSize.sm),
    menuChildren: [
      for (final key in ['user', 'report', 'notification'])
        MenuItemButton(
          onPressed: () => showComingSoonInfo(context, icon: Icons.schedule_outlined, title: 'common.coming_soon_title'.tr(), message: 'admin.topbar.quickSoon'.tr()),
          child: Text('admin.topbar.quick.$key'.tr()),
        ),
    ],
  );
}