import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';

/// The stories strip at the top of the feed. Only "Crea story" exists until
/// stories have a backend; the rest of the row states explicitly that there
/// is no story today instead of showing placeholder avatars.
class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final cardWidth = isWide ? 100.0 : 92.0;
    final cardHeight = isWide ? 170.0 : 160.0;

    final row = SizedBox(
      height: cardHeight,
      child: Row(
        children: [
          _CreateStoryCard(width: cardWidth, height: cardHeight, onTap: () => showComposerSheet(context)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Center(
              child: Text(
                'home.stories_empty'.tr(),
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );

    if (!isWide) return row;
    return HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: row);
  }
}

class _CreateStoryCard extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const _CreateStoryCard({required this.width, required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: LightModeColors.lightPrimaryOutline, radius: AppRadius.md),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomRight,
                children: [
                  const HBAvatar(size: 44, isGuest: true),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: LightModeColors.lightPrimary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'home.create_story'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hand-rolled dashed rounded-rect border (no extra package) for the
/// "Crea story" tile.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 5.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
