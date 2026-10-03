import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Pill-shaped primary action button. Green is used only for this button and
/// other active states across the app.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LightModeColors.lightPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LightModeColors.lightPrimary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: AppSpacing.sm)],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

/// Secondary, low-emphasis button. Uses a tinted fill instead of a visible
/// border, matching the "no outlines" visual language of the app.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const AppSecondaryButton({super.key, required this.label, required this.onPressed, this.height = 52});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LightModeColors.lightSurfaceVariant,
          foregroundColor: LightModeColors.lightOnSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: LightModeColors.lightOnSurface),
        ),
      ),
    );
  }
}

/// A simple text-only link button (e.g. "Forgot password?").
class AppTextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const AppTextLink({super.key, required this.label, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? LightModeColors.lightPrimary,
        ),
      ),
    );
  }
}
