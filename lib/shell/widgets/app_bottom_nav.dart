import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/shell/shell_destinations.dart';
import 'package:hb_social/shell/widgets/mobile_more_sheet.dart';

/// Branch indexes reachable only from the "Altro" sheet, used to highlight
/// that slot when one of them is the active destination.
final Set<int> _moreBranchIndexes = {
  AppRoutes.branchIndexOf(AppRoutes.search)!,
  AppRoutes.branchIndexOf(AppRoutes.notifications)!,
  AppRoutes.branchIndexOf(AppRoutes.forum)!,
  AppRoutes.branchIndexOf(AppRoutes.pages)!,
  AppRoutes.branchIndexOf(AppRoutes.events)!,
  AppRoutes.branchIndexOf(AppRoutes.hunting)!,
  AppRoutes.branchIndexOf(AppRoutes.messages)!,
  AppRoutes.branchIndexOf(AppRoutes.profile)!,
};

/// 5-slot bottom navigation bar for mobile layouts: Home, Gruppi, a raised
/// create button, Market and "Altro" (which opens [showMobileMoreSheet]
/// instead of navigating to a branch).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNav({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final destination in bottomNavLeadingDestinations)
                Expanded(
                  child: _BottomNavTile(
                    icon: destination.icon,
                    label: destination.labelKey.tr(),
                    isActive: destination.branchIndex == currentIndex,
                    onTap: () => onDestinationSelected(destination.branchIndex),
                  ),
                ),
              Expanded(child: _CreateButton(onTap: () => showComposerSheet(context))),
              Expanded(
                child: _BottomNavTile(
                  icon: bottomNavTrailingDestination.icon,
                  label: bottomNavTrailingDestination.labelKey.tr(),
                  isActive: bottomNavTrailingDestination.branchIndex == currentIndex,
                  onTap: () => onDestinationSelected(bottomNavTrailingDestination.branchIndex),
                ),
              ),
              Expanded(
                child: _BottomNavTile(
                  icon: Icons.more_horiz_rounded,
                  label: 'nav.more'.tr(),
                  isActive: _moreBranchIndexes.contains(currentIndex),
                  onTap: () => showMobileMoreSheet(context, currentIndex: currentIndex, onDestinationSelected: onDestinationSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Center(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: LightModeColors.lightPrimary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.level2,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _BottomNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavTile({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? LightModeColors.lightPrimary : LightModeColors.lightOnSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(color)),
        ],
      ),
    );
  }
}
