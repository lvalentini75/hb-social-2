import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';

class DeferredPage extends StatefulWidget {
  final Future<void> Function() loader;
  final Widget Function() builder;
  const DeferredPage({super.key, required this.loader, required this.builder});
  @override State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  late final Future<void> future = widget.loader();
  @override Widget build(BuildContext context) => FutureBuilder<void>(future: future, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) return widget.builder();
    return const ColoredBox(color: LightModeColors.pageMobile, child: SafeArea(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: SizedBox(width: 480, child: HBSkeleton(height: 240))))));
  });
}