import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';

/// A titled form section with the shared vertical rhythm.
class HBFormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const HBFormSection({super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.lightOnSurface)),
    if (subtitle != null) ...[const SizedBox(height: AppSpacing.xs), Text(subtitle!, style: context.textStyles.bodySmall?.copyWith(fontSize: 13, color: LightModeColors.lightOnSurfaceVariant))],
    const SizedBox(height: AppSpacing.sm),
    for (var index = 0; index < children.length; index++) ...[if (index > 0) const SizedBox(height: AppSpacing.md), children[index]],
  ]);
}

/// Label, validation copy and full-width control used by every form.
class HBFormField extends StatelessWidget {
  final String label;
  final bool required;
  final String? helper;
  final String? error;
  final Widget child;

  const HBFormField({super.key, required this.label, this.required = false, this.helper, this.error, required this.child});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text.rich(TextSpan(children: [TextSpan(text: label), if (required) const TextSpan(text: ' *', style: TextStyle(color: LightModeColors.lightError))]), style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.lightOnSurfaceVariant)),
    const SizedBox(height: 6),
    child,
    if (error != null || helper != null) ...[const SizedBox(height: 6), Text(error ?? helper!, style: context.textStyles.bodySmall?.copyWith(fontSize: 12, color: error == null ? LightModeColors.lightTextTertiary : LightModeColors.lightError))],
  ]);
}

/// Single-choice segmented control with one changing description line.
class HBChoice<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T option) labelBuilder;
  final Map<T, String>? descriptions;

  const HBChoice({super.key, required this.options, required this.value, required this.onChanged, required this.labelBuilder, this.descriptions});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SizedBox(height: 44, child: HBSegmentedTabs(labels: options.map(labelBuilder).toList(), selectedIndex: options.indexOf(value).clamp(0, options.length - 1), onChanged: (index) => onChanged(options[index]))),
    if (descriptions?[value] != null) ...[const SizedBox(height: 6), Text(descriptions![value]!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightOnSurfaceVariant))],
  ]);
}

enum HBImageFieldKind { avatar, cover }

/// Shared avatar/cover picker presentation. Upload state is owned by the form.
class HBImageField extends StatelessWidget {
  final HBImageFieldKind kind;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback? onPick;
  final double? progress;
  final VoidCallback? onRemove;
  final String changeLabel;
  final String removeLabel;
  final double coverAspectRatio;

  const HBImageField({super.key, required this.kind, this.imageUrl, this.imageBytes, required this.onPick, this.progress, this.onRemove, required this.changeLabel, required this.removeLabel, this.coverAspectRatio = 3});

  @override
  Widget build(BuildContext context) {
    final avatar = kind == HBImageFieldKind.avatar;
    final image = imageBytes != null ? Image.memory(imageBytes!, fit: BoxFit.cover) : imageUrl?.isNotEmpty == true ? Image.network(imageUrl!, fit: BoxFit.cover) : ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(avatar ? Icons.groups_rounded : Icons.landscape_outlined, color: LightModeColors.lightOnSurfaceVariant));
    final preview = Material(color: Colors.transparent, child: InkWell(onTap: onPick, child: Stack(fit: StackFit.expand, children: [image, Container(color: Colors.black.withValues(alpha: 0.28), alignment: Alignment.center, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_camera_outlined, color: Colors.white), const SizedBox(height: AppSpacing.xs), Text(changeLabel, style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.white))]))])));
    return Column(crossAxisAlignment: avatar ? CrossAxisAlignment.center : CrossAxisAlignment.stretch, children: [
      if (progress != null) ...[HBUploadProgress(progress: progress), const SizedBox(height: AppSpacing.sm)],
      if (avatar) ClipOval(child: SizedBox(width: 96, height: 96, child: preview)) else ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: AspectRatio(aspectRatio: coverAspectRatio, child: preview)),
      if (onRemove != null) Align(alignment: avatar ? Alignment.center : Alignment.centerLeft, child: HBButton.ghost(label: removeLabel, onPressed: onRemove, size: HBButtonSize.sm)),
    ]);
  }
}

/// Shared cancel/submit row. Place it in a bottom SafeArea on mobile.
class HBFormActions extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool loading;

  const HBFormActions({super.key, required this.primaryLabel, required this.onPrimary, this.secondaryLabel, this.onSecondary, this.loading = false});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Row(children: [
    if (secondaryLabel != null) HBButton.ghost(label: secondaryLabel!, onPressed: loading ? null : onSecondary),
    const Spacer(),
    ConstrainedBox(constraints: const BoxConstraints(minWidth: 140), child: HBButton.primary(label: primaryLabel, onPressed: loading ? null : onPrimary, isLoading: loading)),
  ]));
}

/// Inserts the only divider allowed between form sections.
class HBFormSectionDivider extends StatelessWidget {
  const HBFormSectionDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: Divider(height: 1, color: LightModeColors.lightDivider));
}