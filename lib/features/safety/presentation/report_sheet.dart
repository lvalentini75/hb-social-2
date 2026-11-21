import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';

const safetyReportReasons = ['spam', 'harassment', 'hate', 'violence', 'animal_abuse', 'illegal', 'sensitive', 'scam', 'other'];

Future<bool> showReportSheet(BuildContext context, {required String targetType, required String targetId, String titleKey = 'safety.report_title'}) async {
  final wide = MediaQuery.sizeOf(context).width >= 900;
  final result = wide
      ? await showDialog<bool>(context: context, builder: (_) => Dialog(child: SizedBox(width: 480, child: ReportSheet(targetType: targetType, targetId: targetId, titleKey: titleKey))))
      : await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => ReportSheet(targetType: targetType, targetId: targetId, titleKey: titleKey));
  return result ?? false;
}

/// Shared report form for posts, comments, profiles and stories.
class ReportSheet extends ConsumerStatefulWidget {
  final String targetType;
  final String targetId;
  final String titleKey;

  const ReportSheet({super.key, required this.targetType, required this.targetId, this.titleKey = 'safety.report_title'});

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _details = TextEditingController();
  String? _reason;
  bool _sending = false;

  @override
  void dispose() { _details.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_sending || _reason == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(safetyRepositoryProvider).report(targetType: widget.targetType, targetId: widget.targetId, reason: _reason!, details: _details.text);
      if (mounted) context.pop(true);
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.titleKey.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.xs),
      Text('safety.report_subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.md),
      for (final reason in safetyReportReasons) RadioListTile<String>(value: reason, groupValue: _reason, contentPadding: EdgeInsets.zero, title: Text('safety.reasons.$reason'.tr()), onChanged: _sending ? null : (value) => setState(() => _reason = value)),
      const SizedBox(height: AppSpacing.sm),
      HBInput(controller: _details, hint: 'safety.report_details'.tr(), maxLines: 4, maxLength: 1000, onChanged: (_) => setState(() {})),
      Align(alignment: Alignment.centerRight, child: Text('${_details.text.length}/1000', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
      const SizedBox(height: AppSpacing.md),
      SizedBox(width: double.infinity, child: HBButton.primary(label: 'safety.report_submit'.tr(), onPressed: _reason == null || _sending ? null : _submit, isLoading: _sending)),
    ])),
  );
}