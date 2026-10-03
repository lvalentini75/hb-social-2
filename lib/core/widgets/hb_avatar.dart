import 'package:flutter/material.dart';
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

/// Circular avatar showing the user's initials (or a guest icon), with an
/// optional online presence dot and an optional ring. There is no avatar
/// upload yet, so this is always used in place of a photo.
class HBAvatar extends StatelessWidget {
  final String? name;
  final HBAvatarSize avatarSize;
  final double? size;
  final bool showOnlineDot;
  final bool isGuest;
  final Color? ringColor;
  final VoidCallback? onTap;

  const HBAvatar({
    super.key,
    this.name,
    this.avatarSize = HBAvatarSize.md,
    this.size,
    this.showOnlineDot = false,
    this.isGuest = false,
    this.ringColor,
    this.onTap,
  });

  double get _resolvedSize => size ?? avatarSize.px;

  String get _initials {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = _resolvedSize;
    Widget circle = CircleAvatar(
      radius: s / 2,
      backgroundColor: LightModeColors.lightPrimarySoft,
      child: isGuest
          ? Icon(Icons.person_outline_rounded, size: s * 0.52, color: LightModeColors.lightForest)
          : Text(
              _initials,
              style: context.textStyles.labelLarge?.withColor(LightModeColors.lightForest).copyWith(fontSize: s * 0.4, fontWeight: FontWeight.w700),
            ),
    );

    if (ringColor != null) {
      circle = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor!, width: 2)),
        child: circle,
      );
    }

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        if (showOnlineDot)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: s * 0.3,
              height: s * 0.3,
              decoration: BoxDecoration(
                color: LightModeColors.lightSuccess,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
    if (onTap == null) return avatar;
    return InkWell(borderRadius: BorderRadius.circular(s), onTap: onTap, child: avatar);
  }
}
