import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

enum HBButtonVariant { primary, secondary, soft, ghost, icon }

/// md = 44px (default), sm = 36px (compact rows, toolbars, inline actions).
enum HBButtonSize { lg, md, sm }

/// The single button family used across HB Social. Green ([HBButton.primary])
/// is reserved for the one main action per screen; every other role uses a
/// neutral, borderless variant.
class HBButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool isLoading;
  final HBButtonSize size;
  final HBButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const HBButton.primary({super.key, required String this.label, required this.onPressed, this.icon, this.leading, this.isLoading = false, this.size = HBButtonSize.md})
    : variant = HBButtonVariant.primary, backgroundColor = null, foregroundColor = null, tooltip = null;

  const HBButton.secondary({super.key, required String this.label, required this.onPressed, this.icon, this.leading, this.isLoading = false, this.size = HBButtonSize.md, this.backgroundColor, this.foregroundColor})
    : variant = HBButtonVariant.secondary, tooltip = null;

  const HBButton.soft({super.key, required String this.label, required this.onPressed, this.icon, this.isLoading = false, this.size = HBButtonSize.md})
    : variant = HBButtonVariant.soft, leading = null, backgroundColor = null, foregroundColor = null, tooltip = null;

  const HBButton.ghost({super.key, required String this.label, required this.onPressed, this.icon, this.isLoading = false, this.size = HBButtonSize.md, this.foregroundColor})
    : variant = HBButtonVariant.ghost, leading = null, backgroundColor = null, tooltip = null;

  const HBButton.icon({super.key, required IconData this.icon, required this.onPressed, this.size = HBButtonSize.md, this.backgroundColor, this.foregroundColor, this.tooltip})
    : variant = HBButtonVariant.icon,
      label = null,
      leading = null,
      isLoading = false;

  double get height => size == HBButtonSize.sm ? 40 : 44;

  @override
  State<HBButton> createState() => _HBButtonState();
}

class _HBButtonState extends State<HBButton> {
  bool pressed = false;
  bool hovered = false;
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color defaultForeground;
    switch (widget.variant) {
      case HBButtonVariant.primary:
        background = hovered ? LightModeColors.lightPrimaryHover : LightModeColors.lightPrimary;
        defaultForeground = Colors.white;
        break;
      case HBButtonVariant.secondary:
        background = LightModeColors.lightSurface;
        defaultForeground = LightModeColors.lightPrimary;
        break;
      case HBButtonVariant.soft:
        background = LightModeColors.lightPrimarySoft;
        defaultForeground = LightModeColors.lightForest;
        break;
      case HBButtonVariant.ghost:
        background = Colors.transparent;
        defaultForeground = LightModeColors.lightOnSurface;
        break;
      case HBButtonVariant.icon:
        background = LightModeColors.lightBackgroundSoft;
        defaultForeground = LightModeColors.lightOnSurfaceVariant;
        break;
    }

    if (widget.variant == HBButtonVariant.icon) {
      final semanticsLabel = widget.tooltip ?? 'a11y.icon_action'.tr();
      final button = _interaction(SizedBox(
        width: widget.height,
        height: widget.height,
        child: Material(
         color: widget.backgroundColor ?? background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            child: Icon(widget.icon, size: 20, color: widget.foregroundColor ?? defaultForeground),
          ),
        ),
      ));
      return Semantics(button: true, enabled: widget.onPressed != null, label: semanticsLabel, child: Tooltip(message: semanticsLabel, child: button));
    }

    return Semantics(button: true, enabled: widget.onPressed != null, label: widget.label, child: _interaction(SizedBox(
      height: widget.height,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? background,
          foregroundColor: widget.foregroundColor ?? defaultForeground,
          disabledBackgroundColor: widget.variant == HBButtonVariant.ghost ? Colors.transparent : (widget.backgroundColor ?? background).withValues(alpha: 0.45),
          disabledForegroundColor: (widget.foregroundColor ?? defaultForeground).withValues(alpha: 0.45),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          side: widget.variant == HBButtonVariant.secondary ? const BorderSide(color: LightModeColors.lightBorder) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        child: widget.isLoading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: widget.foregroundColor ?? defaultForeground))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null || widget.leading != null) ...[
                    widget.leading ?? Icon(widget.icon, size: widget.size == HBButtonSize.sm ? 16 : 18, color: widget.foregroundColor ?? defaultForeground),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label ?? '',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: widget.foregroundColor ?? defaultForeground),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    )));
  }

  Widget _interaction(Widget child) => Focus(
    onFocusChange: (value) => setState(() => focused = value),
    child: AnimatedContainer(duration: AppMotion.of(context).fast, decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: focused ? Border.all(color: LightModeColors.bosco, width: 2) : null), child: MouseRegion(
    onEnter: (_) => setState(() => hovered = true), onExit: (_) => setState(() => hovered = false),
    child: Listener(onPointerDown: widget.onPressed == null ? null : (_) => setState(() => pressed = true), onPointerUp: (_) => setState(() => pressed = false), onPointerCancel: (_) => setState(() => pressed = false), child: AnimatedScale(scale: pressed ? 0.98 : 1, duration: AppMotion.of(context).fast, curve: AppMotion.enter, child: child)),
  )));
}
