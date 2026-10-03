import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

enum HBButtonVariant { primary, secondary, soft, ghost, icon }

/// md = 44px (default), sm = 36px (compact rows, toolbars, inline actions).
enum HBButtonSize { md, sm }

/// The single button family used across HB Social. Green ([HBButton.primary])
/// is reserved for the one main action per screen; every other role uses a
/// neutral, borderless variant.
class HBButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final HBButtonSize size;
  final HBButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const HBButton.primary({super.key, required String this.label, required this.onPressed, this.icon, this.isLoading = false, this.size = HBButtonSize.md})
    : variant = HBButtonVariant.primary, backgroundColor = null, foregroundColor = null;

  const HBButton.secondary({super.key, required String this.label, required this.onPressed, this.icon, this.isLoading = false, this.size = HBButtonSize.md, this.foregroundColor})
    : variant = HBButtonVariant.secondary, backgroundColor = null;

  const HBButton.soft({super.key, required String this.label, required this.onPressed, this.icon, this.isLoading = false, this.size = HBButtonSize.md})
    : variant = HBButtonVariant.soft, backgroundColor = null, foregroundColor = null;

  const HBButton.ghost({super.key, required String this.label, required this.onPressed, this.icon, this.isLoading = false, this.size = HBButtonSize.md, this.foregroundColor})
    : variant = HBButtonVariant.ghost, backgroundColor = null;

  const HBButton.icon({super.key, required IconData this.icon, required this.onPressed, this.size = HBButtonSize.md, this.backgroundColor, this.foregroundColor})
    : variant = HBButtonVariant.icon,
      label = null,
      isLoading = false;

  double get _height => size == HBButtonSize.sm ? 36 : 44;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color defaultForeground;
    switch (variant) {
      case HBButtonVariant.primary:
        background = LightModeColors.lightPrimary;
        defaultForeground = Colors.white;
        break;
      case HBButtonVariant.secondary:
        background = LightModeColors.lightBackgroundSoft;
        defaultForeground = LightModeColors.lightOnSurface;
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

    if (variant == HBButtonVariant.icon) {
      return SizedBox(
        width: _height,
        height: _height,
        child: Material(
         color: backgroundColor ?? background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(icon, size: 20, color: foregroundColor ?? defaultForeground),
          ),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foregroundColor ?? defaultForeground,
          disabledBackgroundColor: variant == HBButtonVariant.ghost ? Colors.transparent : background.withValues(alpha: 0.5),
          disabledForegroundColor: variant == HBButtonVariant.ghost ? LightModeColors.lightTextTertiary : (foregroundColor ?? defaultForeground).withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: isLoading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: foregroundColor ?? defaultForeground))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: size == HBButtonSize.sm ? 16 : 18, color: foregroundColor ?? defaultForeground),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label ?? '',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: foregroundColor ?? defaultForeground),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
