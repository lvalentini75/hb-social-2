import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/shell/shell_destinations.dart';

/// PD4 mobile bottom bar: white, 64 px plus safe area, upward shadow and the
/// raised central create FAB. Home, Cerca, [+], Notifiche, Profilo.
class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNav({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotifications = (ref.watch(unreadNotificationCountProvider).value ?? 0) > 0;
    return Container(
      decoration: const BoxDecoration(color: LightModeColors.surface, boxShadow: AppShadows.bottomBar),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (final destination in bottomNavLeadingDestinations)
              Expanded(child: BottomNavTile(
                icon: destination.icon,
                label: destination.labelKey.tr(),
                isActive: destination.branchIndex == currentIndex,
                onTap: () => onDestinationSelected(destination.branchIndex),
              )),
            Expanded(child: BottomNavCreateButton(onTap: () => showCreateMenu(context))),
            Expanded(child: BottomNavTile(
              icon: bottomNavTrailingDestination.icon,
              label: bottomNavTrailingDestination.labelKey.tr(),
              isActive: bottomNavTrailingDestination.branchIndex == currentIndex,
              hasDot: hasNotifications,
              onTap: () => onDestinationSelected(bottomNavTrailingDestination.branchIndex),
            )),
            Expanded(child: BottomNavTile(
              icon: Icons.person_outline_rounded,
              label: 'nav.profile'.tr(),
              isActive: AppRoutes.branchIndexOf(AppRoutes.profile) == currentIndex,
              onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.profile)!),
            )),
          ]),
        ),
      ),
    );
  }
}

/// Central 64 px Bosco FAB lifted 20 px above the bar.
class BottomNavCreateButton extends StatefulWidget {
  final Future<void> Function() onTap;

  const BottomNavCreateButton({super.key, required this.onTap});

  @override
  State<BottomNavCreateButton> createState() => _BottomNavCreateButtonState();
}

class _BottomNavCreateButtonState extends State<BottomNavCreateButton> {
  bool open = false;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -20),
    child: Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          setState(() => open = true);
          await widget.onTap();
          if (mounted) setState(() => open = false);
        },
        child: Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(color: LightModeColors.bosco, shape: BoxShape.circle, boxShadow: AppShadows.fab),
          child: AnimatedRotation(turns: open ? .125 : 0, duration: AppMotion.of(context).base, child: const Icon(Icons.add_rounded, color: Colors.white, size: 28)),
        ),
      ),
    ),
  );
}

/// Bottom bar slot: 24 px icon and a 12/500 label, no ripple.
class BottomNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool hasDot;
  final VoidCallback onTap;

  const BottomNavTile({super.key, required this.icon, required this.label, required this.isActive, required this.onTap, this.hasDot = false});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? LightModeColors.bosco : LightModeColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(clipBehavior: Clip.none, children: [
          Icon(icon, color: color, size: 24),
          if (hasDot) Positioned(right: -2, top: -1, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: LightModeColors.danger, shape: BoxShape.circle, border: Border.all(color: LightModeColors.surface, width: 2)))),
        ]),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.withColor(color)),
      ]),
    );
  }
}
