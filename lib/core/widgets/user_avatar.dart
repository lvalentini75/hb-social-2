import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Circular avatar showing the user's initials. There is no avatar upload
/// yet, so this is always used in place of a photo.
class UserAvatar extends StatelessWidget {
  final String? name;
  final double radius;
  final Color? background;
  final Color? foreground;

  const UserAvatar({super.key, required this.name, this.radius = 18, this.background, this.foreground});

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
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? colors.primaryContainer,
      child: Text(
        _initials,
        style: context.textStyles.labelLarge?.withColor(foreground ?? colors.primary).copyWith(fontSize: radius * 0.65),
      ),
    );
  }
}
