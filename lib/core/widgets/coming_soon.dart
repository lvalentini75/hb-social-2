import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shared feedback for navigation destinations and actions that are not part
/// of this build yet.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('common.coming_soon'.tr())));
}
