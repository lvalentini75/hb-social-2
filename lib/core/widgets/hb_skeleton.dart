import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Hand-rolled shimmer block (no plugin): a soft base color with a moving
/// lighter gradient sweep, used everywhere a list is loading instead of a
/// spinner.
class HBSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const HBSkeleton({super.key, this.height = 16, this.width, this.radius = AppRadius.xs});

  @override
  State<HBSkeleton> createState() => _HBSkeletonState();
}

class _HBSkeletonState extends State<HBSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + _controller.value * 3, 0),
                  end: Alignment(0 + _controller.value * 3, 0),
                  colors: const [
                    LightModeColors.lightBackgroundSoft,
                    LightModeColors.lightBackgroundHover,
                    LightModeColors.lightBackgroundSoft,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
