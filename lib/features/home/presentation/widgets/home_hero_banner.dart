import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_marketing_image.dart';

/// Web-only 180 px hero at the top of the Home feed.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) => HBMarketingImage(
    asset: 'assets/images/hero_home.jpg',
    height: 180,
    dimLeft: true,
    overlayChild: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: Text('home.hero_title'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.hero.withColor(Colors.white))),
          const SizedBox(height: AppSpacing.sm),
          Text('home.hero_subtitle'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: appFont(18, FontWeight.w400, color: Colors.white)),
        ]),
      ),
    ),
  );
}
