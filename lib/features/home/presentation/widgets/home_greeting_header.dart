import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Compact localized date shown above the mobile home content.
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key});

  @override
  Widget build(BuildContext context) => Text(DateFormat.MMMMEEEEd(context.locale.languageCode).format(DateTime.now()), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.textSecondary));
}
