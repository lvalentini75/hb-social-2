import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// PD4 navigation row: 44 px tall, radius 12, icon 22, label 15/500.
/// Active = solid Bosco with white icon and label; hover = boscoTint.
class SidebarNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;
  final Widget? trailing;

  const SidebarNavTile({super.key, required this.icon, required this.label, required this.isActive, required this.onTap, this.badgeCount, this.trailing});

  @override
  State<SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<SidebarNavTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isActive ? Colors.white : LightModeColors.text;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: AnimatedContainer(
          duration: AppMotion.of(context).base,
          height: 44,
          decoration: BoxDecoration(color: widget.isActive ? LightModeColors.bosco : hovered ? LightModeColors.boscoTint : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.nav)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.nav),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(widget.icon, size: 22, color: widget.isActive ? Colors.white : LightModeColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.withColor(foreground))),
                  if (widget.badgeCount != null) NavCountBadge(count: widget.badgeCount!),
                  if (widget.trailing != null) widget.trailing!,
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Danger pill used for unread counters next to a navigation row.
class NavCountBadge extends StatelessWidget {
  final int count;

  const NavCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22),
    height: 22,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(color: LightModeColors.danger, borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(count > 99 ? '99+' : '$count', style: appFont(12, FontWeight.w700, color: Colors.white)),
  );
}
