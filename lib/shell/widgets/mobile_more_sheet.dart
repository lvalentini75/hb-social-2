import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Bottom sheet opened by the mobile bottom bar's "Altro" slot: the shell
/// destinations that don't fit in the 5-slot bar, including Settings.
Future<void> showMobileMoreSheet(BuildContext context, {required int currentIndex, required ValueChanged<int> onDestinationSelected}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => SafeArea(child: _MoreSheetContent(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected)),
  );
}

class _MoreDestination {
  final IconData icon;
  final String labelKey;
  final String path;

  const _MoreDestination({required this.icon, required this.labelKey, required this.path});
}

const List<_MoreDestination> _moreDestinations = [
  _MoreDestination(icon: Icons.forum_outlined, labelKey: 'nav.forum', path: AppRoutes.forum),
  _MoreDestination(icon: Icons.article_outlined, labelKey: 'nav.pages', path: AppRoutes.pages),
  _MoreDestination(icon: Icons.event_outlined, labelKey: 'nav.events', path: AppRoutes.events),
  _MoreDestination(icon: Icons.terrain_outlined, labelKey: 'nav.hunting', path: AppRoutes.hunting),
  _MoreDestination(icon: Icons.chat_bubble_outline_rounded, labelKey: 'nav.messages', path: AppRoutes.messages),
  _MoreDestination(icon: Icons.notifications_none_rounded, labelKey: 'nav.notifications', path: AppRoutes.notifications),
  _MoreDestination(icon: Icons.person_outline_rounded, labelKey: 'nav.profile', path: AppRoutes.profile),
  _MoreDestination(icon: Icons.settings_outlined, labelKey: 'settings.title', path: AppRoutes.settings),
];

class _MoreSheetContent extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _MoreSheetContent({required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final destination in _moreDestinations)
            _MoreSheetTile(
              icon: destination.icon,
              label: destination.labelKey.tr(),
              isActive: AppRoutes.branchIndexOf(destination.path) == currentIndex,
              onTap: () {
                 final router = GoRouter.of(context);
                 context.pop();
                 if (destination.path == AppRoutes.settings) {
                   router.go(destination.path);
                 } else {
                   onDestinationSelected(AppRoutes.branchIndexOf(destination.path)!);
                 }
              },
            ),
        ],
      ),
    );
  }
}

class _MoreSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MoreSheetTile({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? LightModeColors.lightForest : LightModeColors.lightOnSurface;
    return Material(
      color: isActive ? LightModeColors.lightPrimarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isActive ? LightModeColors.lightForest : LightModeColors.lightOnSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: context.textStyles.bodyMedium?.withColor(color).copyWith(fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
