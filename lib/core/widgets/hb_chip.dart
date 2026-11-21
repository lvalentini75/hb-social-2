import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// PD4b pill chip: 40 px tall, radius 999.
/// Selected = Bosco background with white 14/600 text; unselected = white with
/// a 1 px border and 14/500 text.
class HBChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? colorDot;
  final VoidCallback? onDeleted;

  /// Small inline tag (26 px, surfaceSoft, 12/500) used inside cards.
  final bool tag;

  const HBChip({super.key, required this.label, this.selected = false, this.onTap, this.icon, this.colorDot, this.onDeleted, this.tag = false});

  @override
  State<HBChip> createState() => _HBChipState();
}

class _HBChipState extends State<HBChip> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tag) {
      return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.withColor(LightModeColors.text)),
      );
    }
    final background = widget.selected ? LightModeColors.bosco : LightModeColors.surface;
    final foreground = widget.selected ? Colors.white : LightModeColors.text;
    final style = widget.selected ? AppText.buttonSm.withColor(foreground) : AppText.label.withColor(foreground);
    return Listener(
      onPointerDown: widget.onTap == null ? null : (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(scale: pressed ? 0.98 : 1, duration: AppMotion.of(context).fast, child: Material(
        color: background,
        shape: StadiumBorder(side: widget.selected ? BorderSide.none : const BorderSide(color: LightModeColors.border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: widget.onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 16, color: foreground), const SizedBox(width: 6)],
                if (widget.colorDot != null) ...[Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.colorDot, shape: BoxShape.circle)), const SizedBox(width: 6)],
                Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
                if (widget.onDeleted != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(onTap: widget.onDeleted, behavior: HitTestBehavior.opaque, child: Icon(Icons.close_rounded, size: 16, color: foreground)),
                ],
              ],
            ),
          ),
        ),
      )),
    );
  }
}
