import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import 'package:hb_social/features/admin/domain/admin_role.dart';
import 'package:hb_social/features/admin/providers/admin_session_provider.dart';
import 'package:hb_social/features/admin/providers/admin_preview_provider.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String periodKey = 'admin.topbar.period30';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final drawerMode = width < 900;
    final compact = width < 1280;
    final location = GoRouterState.of(context).uri.path;
    final slug = location == '/admin' ? '' : location.replaceFirst('/admin/', '');
    final module = adminModuleForSlug(slug) ?? adminModuleForSlug('')!;

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

  String _path(BuildContext context, String slug) {
    final query = GoRouterState.of(context).uri.query;
    return '${slug.isEmpty ? '/admin' : '/admin/$slug'}${query.isEmpty ? '' : '?$query'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugPreview = Env.previewEnabled && ref.watch(adminPreviewProvider);
    final session = ref.watch(adminSessionProvider);
    final width = compact ? 64.0 : 248.0;
    return Container(
      width: width,
      color: LightModeColors.adminSidebar,
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
                          Text('admin.consoleLabel'.tr().toUpperCase(), style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7)),
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
                  for (final section in adminModuleSections) ...[
                    if (!compact) AdminSidebarSectionLabel(label: section.labelKey.tr()),
                    for (final module in section.modules)
                      AdminSidebarTile(
                        compact: compact,
                        icon: module.icon,
                        label: module.titleKey.tr(),
                        selected: module.slug == currentSlug,
                        count: 0,
                        onTap: () {
                          context.go(_path(context, module.slug));
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
              name: debugPreview ? 'admin.account.preview'.tr() : session.displayName ?? 'admin.account.guest'.tr(),
              meta: debugPreview ? 'admin.account.previewMeta'.tr() : 'admin.account.unauthenticated'.tr(),
              role: debugPreview ? null : session.role,
              onTap: () => context.go('/admin/login'),
              preview: debugPreview,
              onExitPreview: () {
                if (!Env.previewEnabled) return;
                ref.read(adminPreviewProvider.notifier).state = false;
                context.go('/admin/login');
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
    child: Text(label.toUpperCase(), style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7)),
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
      color: selected ? LightModeColors.adminSidebarActive : Colors.transparent,
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
    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class AdminSidebarAccountCard extends StatelessWidget {
  final bool compact;
  final String name;
  final String meta;
  final AdminRole? role;
  final VoidCallback onTap;
  final bool preview;
  final VoidCallback onExitPreview;

  const AdminSidebarAccountCard({super.key, required this.compact, required this.name, required this.meta, this.role, required this.onTap, required this.preview, required this.onExitPreview});

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: preview ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : AppSpacing.sm),
          child: Row(
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              HBAvatar(size: 36, name: name, isGuest: preview || name == 'admin.account.guest'.tr()),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      if (role == null)
                        Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 11))
                      else
                        Row(children: [Flexible(child: HBStatusChip(kind: role!.statusKind, label: role!.labelKey.tr())), Text(' · ${'admin.account.twoFactor'.tr()}', style: const TextStyle(color: LightModeColors.adminSidebarMuted, fontSize: 11))]),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline, size: 18, color: LightModeColors.adminSidebarMuted),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: preview
          ? PopupMenuButton<bool>(
              tooltip: 'admin.account.preview'.tr(),
              onSelected: (_) => onExitPreview(),
              itemBuilder: (context) => [PopupMenuItem<bool>(value: true, child: Text('admin.account.exitPreview'.tr()))],
              child: card,
            )
          : card,
    );
  }
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
          if (Env.previewEnabled && ref.watch(adminPreviewProvider)) ...[
            const SizedBox(width: AppSpacing.xs),
            HBStatusChip(kind: HBStatusKind.pending, label: 'admin.topbar.preview'.tr()),
          ],
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