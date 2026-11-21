import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Preset sizes used across the app, per docs/DESIGN_SYSTEM.md.
enum HBAvatarSize { xs, sm, md, lg, xl }

extension on HBAvatarSize {
  double get px {
    switch (this) {
      case HBAvatarSize.xs:
        return 24;
      case HBAvatarSize.sm:
        return 32;
      case HBAvatarSize.md:
        return 40;
      case HBAvatarSize.lg:
        return 56;
      case HBAvatarSize.xl:
        return 96;
    }
  }
}

/// Circular avatar showing a remote image with initials as its fallback.
class HBAvatar extends StatelessWidget {
  final String? name;
  final HBAvatarSize avatarSize;
  final double? size;
  final bool showOnlineDot;
  final bool showPresence;
  final bool isGuest;
  final String? imageUrl;
  final Color? ringColor;
  final double ringWidth;
  final VoidCallback? onTap;

  /// Shows a single uppercase initial instead of two, for tight spaces like
  /// the right-rail attendee stack.
  final bool singleInitial;
  final Color? initialsColor;
  final double? initialsFontSize;
  final FontWeight? initialsFontWeight;

  const HBAvatar({
    super.key,
    this.name,
    this.avatarSize = HBAvatarSize.md,
    this.size,
    this.showOnlineDot = false,
    this.showPresence = false,
    this.isGuest = false,
    this.imageUrl,
    this.ringColor,
    this.ringWidth = 2,
    this.onTap,
    this.singleInitial = false,
    this.initialsColor,
    this.initialsFontSize,
    this.initialsFontWeight,
  });

  double get _resolvedSize => size ?? avatarSize.px;

  String get _initials {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    if (singleInitial) return first.toUpperCase();
    final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = _resolvedSize;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    Widget circle = CircleAvatar(
      radius: s / 2,
      backgroundColor: LightModeColors.lightPrimarySoft,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      onBackgroundImageError: hasImage ? (_, __) {} : null,
      child: hasImage
          ? null
          : isGuest
          ? Icon(Icons.person_outline_rounded, size: s * 0.52, color: LightModeColors.lightForest)
          : Text(
              _initials,
              style: context.textStyles.labelLarge?.withColor(initialsColor ?? LightModeColors.lightForest).copyWith(fontSize: initialsFontSize ?? s * 0.4, fontWeight: initialsFontWeight ?? FontWeight.w700),
            ),
    );

    if (ringColor != null) {
      circle = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor!, width: ringWidth)),
        child: circle,
      );
    }

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        if (showOnlineDot || showPresence)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
               width: 10,
               height: 10,
              decoration: BoxDecoration(
                color: LightModeColors.lightSuccess,
                shape: BoxShape.circle,
                 border: Border.all(color: LightModeColors.lightSurface, width: 2),
              ),
            ),
          ),
      ],
    );
    final semanticAvatar = Semantics(image: true, button: onTap != null, label: isGuest ? 'a11y.guest_avatar'.tr() : 'a11y.avatar'.tr(namedArgs: {'name': name ?? ''}), child: ExcludeSemantics(child: avatar));
    if (onTap == null) return semanticAvatar;
    return InkWell(borderRadius: BorderRadius.circular(s), onTap: onTap, child: semanticAvatar);
  }
}
