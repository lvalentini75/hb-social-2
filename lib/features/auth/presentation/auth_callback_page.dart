import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';

class AuthCallbackPage extends StatelessWidget {
  const AuthCallbackPage({super.key});
  @override Widget build(BuildContext context) => const ColoredBox(color: LightModeColors.lightBackground, child: Center(child: SizedBox(width: 220, child: HBSkeleton(height: 44))));
}