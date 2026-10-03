import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';

/// Opens the post composer placeholder. Composing real posts arrives with
/// P09, so every create entry point (header button, mobile FAB, home
/// composer row) shows this single explicit empty state instead, using the
/// shared [showComingSoonInfo] chrome.
Future<void> showComposerSheet(BuildContext context) {
  return showComingSoonInfo(context, icon: Icons.edit_outlined, title: 'composer.empty_title'.tr(), message: 'composer.empty_message'.tr());
}
