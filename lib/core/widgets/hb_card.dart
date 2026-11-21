import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Soft, borderless surface used for every card-like block in the app
/// (feed container, rail panels, profile sections, ...). Depth comes from
/// [shadow], never from a visible border.
class HBCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> shadow;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;
  final bool hoverable;

  const HBCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.cardWeb,
    this.shadow = AppShadows.card,
    this.color = Colors.white,
    this.onTap,
    this.compact = false,
    this.hoverable = false,
  });

  /// Edge-to-edge media surface. The child is clipped to the card radius and
  /// intentionally receives no inset or nested shadow.
  const HBCard.media({super.key, required this.child, this.radius = AppRadius.cardWeb, this.color = Colors.white, this.onTap, this.compact = false, this.hoverable = false})
    : padding = EdgeInsets.zero,
      shadow = AppShadows.card;

  @override
  State<HBCard> createState() => _HBCardState();
}

class _HBCardState extends State<HBCard> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final lifts = interactive || widget.hoverable;
    return MouseRegion(
      onEnter: lifts ? (_) => setState(() => hovered = true) : null,
      onExit: lifts ? (_) => setState(() => hovered = false) : null,
      child: Listener(
      onPointerDown: interactive ? (_) => setState(() => pressed = true) : null, onPointerUp: interactive ? (_) => setState(() => pressed = false) : null, onPointerCancel: interactive ? (_) => setState(() => pressed = false) : null,
      child: AnimatedScale(scale: pressed ? 0.98 : 1, duration: AppMotion.of(context).fast, child: AnimatedContainer(
      duration: AppMotion.of(context).base,
      transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(widget.radius), boxShadow: hovered ? AppShadows.hover : widget.shadow, border: hovered ? Border.all(color: LightModeColors.lightBorder) : null),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Material(color: Colors.transparent, child: InkWell(onTap: widget.onTap, child: Padding(padding: widget.compact ? const EdgeInsets.all(16) : widget.padding, child: widget.child))),
      ),
    ))));
  }
}
