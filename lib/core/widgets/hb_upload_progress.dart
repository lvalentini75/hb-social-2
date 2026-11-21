import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Shared upload status used by every media submission flow.
class HBUploadProgress extends StatelessWidget {
  final double? progress;
  final bool publishing;
  final int? fileIndex;
  final int? fileCount;
  final String? errorKey;
  final Map<String, String> errorArgs;

  const HBUploadProgress({super.key, this.progress, this.publishing = false, this.fileIndex, this.fileCount, this.errorKey, this.errorArgs = const {}});

  @override
  Widget build(BuildContext context) {
    final failed = errorKey != null;
    final double? value = publishing ? null : (progress ?? 0).clamp(0, 1).toDouble();
    final percent = ((progress ?? 0).clamp(0, 1) * 100).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(publishing ? 'upload.publishing'.tr() : 'upload.progress'.tr(namedArgs: {'n': '$percent'}), style: context.textStyles.bodySmall?.withColor(failed ? LightModeColors.lightError : LightModeColors.lightOnSurfaceVariant))),
        if (!publishing && fileIndex != null && fileCount != null && fileCount! > 1) Text('upload.file_count'.tr(namedArgs: {'i': '$fileIndex', 'n': '$fileCount'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ]),
      const SizedBox(height: AppSpacing.xs),
      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: LinearProgressIndicator(value: failed ? 1 : value, minHeight: 4, color: failed ? LightModeColors.lightError : LightModeColors.lightPrimary, backgroundColor: LightModeColors.lightBackgroundSoft)),
      if (failed) ...[const SizedBox(height: AppSpacing.xs), Text(errorKey!.tr(namedArgs: errorArgs), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
    ]);
  }
}