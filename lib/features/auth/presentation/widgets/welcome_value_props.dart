import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// The three value propositions shown on the Welcome screen: hunting
/// calendar, maps & zones, community & marketplace. Reused on both the dark
/// web panel and the single mobile column, with adjustable colors.
class WelcomeValueProps extends StatelessWidget {
  final Color iconColor;
  final Color iconBackground;
  final Color textColor;
  final CrossAxisAlignment alignment;
  final double fontSize;
  final FontWeight fontWeight;

  const WelcomeValueProps({
    super.key,
    required this.iconColor,
    required this.iconBackground,
    required this.textColor,
    this.alignment = CrossAxisAlignment.start,
    this.fontSize = FontSizes.bodyLarge,
    this.fontWeight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    // Each row is always left-aligned internally so the icons form a single
    // vertical column; when a centered block is requested, the whole column
    // is centered as one unit via IntrinsicWidth instead of centering each
    // row independently (which would misalign the icons).
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ValueProp(icon: Icons.calendar_month_outlined, label: 'welcome.value_calendar'.tr(), iconColor: iconColor, iconBackground: iconBackground, textColor: textColor, fontSize: fontSize, fontWeight: fontWeight),
        const SizedBox(height: AppSpacing.lg),
        _ValueProp(icon: Icons.map_outlined, label: 'welcome.value_maps'.tr(), iconColor: iconColor, iconBackground: iconBackground, textColor: textColor, fontSize: fontSize, fontWeight: fontWeight),
        const SizedBox(height: AppSpacing.lg),
        _ValueProp(icon: Icons.groups_outlined, label: 'welcome.value_community'.tr(), iconColor: iconColor, iconBackground: iconBackground, textColor: textColor, fontSize: fontSize, fontWeight: fontWeight),
      ],
    );
    if (alignment == CrossAxisAlignment.center) {
      return Center(child: IntrinsicWidth(child: column));
    }
    return column;
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBackground;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const _ValueProp({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBackground,
    required this.textColor,
    required this.fontSize,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(AppRadius.sm)),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(label, style: context.textStyles.bodyLarge?.copyWith(color: textColor, fontSize: fontSize, fontWeight: fontWeight)),
          ),
        ),
      ],
    );
  }
}
