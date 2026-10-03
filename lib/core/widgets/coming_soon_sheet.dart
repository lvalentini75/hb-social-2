import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';

/// Chrome (dialog on wide layouts, bottom sheet on narrow ones) for any
/// "not implemented yet" placeholder: new post, new group, new thread, new
/// page, new message, mark-all-as-read, ... Callers provide the content
/// (usually an [HBEmptyState] via [showComingSoonInfo]) so each surface
/// keeps its own translated copy.
Future<void> showComingSoonSheet(BuildContext context, {required Widget content, double dialogMaxWidth = 440}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

  if (isWide) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: dialogMaxWidth), child: content),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (context) => SafeArea(child: content),
  );
}

/// Convenience wrapper for the common case: an icon + title + message
/// [HBEmptyState] inside the [showComingSoonSheet] chrome.
Future<void> showComingSoonInfo(BuildContext context, {required IconData icon, required String title, required String message}) {
  return showComingSoonSheet(context, content: HBEmptyState(icon: icon, title: title, message: message));
}
