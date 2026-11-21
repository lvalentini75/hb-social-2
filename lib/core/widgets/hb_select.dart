import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_input.dart';

class HBSelectOption<T> {
  final T value;
  final String label;
  final String? groupLabel;

  const HBSelectOption({required this.value, required this.label, this.groupLabel});
}

typedef HBSelectItem<T> = HBSelectOption<T>;

/// Shared select control matching HBInput. Long mobile lists open in a
/// searchable bottom sheet; shorter and desktop lists use an anchored menu.
class HBSelect<T> extends StatefulWidget {
  final T? value;
  final List<HBSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? placeholder;
  final bool allowClear;

  const HBSelect({super.key, required this.value, List<HBSelectOption<T>>? options, List<HBSelectOption<T>>? items, required this.onChanged, this.placeholder, this.allowClear = false}) : options = options ?? items ?? const [];

  @override
  State<HBSelect<T>> createState() => _HBSelectState<T>();
}

class _HBSelectState<T> extends State<HBSelect<T>> {
  bool _open = false;

  Future<void> _showSheet() async {
    setState(() => _open = true);
    final value = await showModalBottomSheet<T>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => HBSelectSheet<T>(options: widget.options, selected: widget.value));
    if (mounted) setState(() => _open = false);
    if (value != null) widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.options.where((item) => item.value == widget.value).firstOrNull;
    final searchableSheet = widget.options.length > 8;
    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: LightModeColors.lightBackgroundSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _open ? LightModeColors.lightPrimary : Colors.transparent, width: 1.5),
      ),
      child: Row(children: [
        Expanded(child: Text(selected?.label ?? widget.placeholder ?? 'common.select'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyLarge?.withColor(selected == null ? LightModeColors.lightTextTertiary : LightModeColors.lightOnSurface))),
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.keyboard_arrow_down_rounded, color: LightModeColors.lightTextTertiary),
      ]),
    );
    if (searchableSheet) return InkWell(onTap: widget.onChanged == null ? null : _showSheet, borderRadius: BorderRadius.circular(AppRadius.sm), child: field);
    return PopupMenuButton<T>(
      enabled: widget.onChanged != null,
      onOpened: () => setState(() => _open = true),
      onCanceled: () => setState(() => _open = false),
      onSelected: (value) { setState(() => _open = false); widget.onChanged?.call(value); },
      itemBuilder: (_) => [
        if (widget.allowClear) PopupMenuItem<T>(value: null, child: Text(widget.placeholder ?? 'common.select'.tr())),
        for (var index = 0; index < widget.options.length; index++) ...[
          if (widget.options[index].groupLabel != null && (index == 0 || widget.options[index - 1].groupLabel != widget.options[index].groupLabel)) PopupMenuItem<T>(enabled: false, height: 34, child: Text(widget.options[index].groupLabel!, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))),
          PopupMenuItem<T>(value: widget.options[index].value, child: Text(widget.options[index].label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ],
      child: field,
    );
  }
}

class HBSelectSheet<T> extends StatefulWidget {
  final List<HBSelectOption<T>> options;
  final T? selected;

  const HBSelectSheet({super.key, required this.options, this.selected});

  @override
  State<HBSelectSheet<T>> createState() => _HBSelectSheetState<T>();
}

class _HBSelectSheetState<T> extends State<HBSelectSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.options.where((item) => item.label.toLowerCase().contains(_query.toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md),
      child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.7, child: Column(children: [
        HBInput(hint: 'common.search'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: (value) => setState(() => _query = value)),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (_, index) { final item = items[index]; final showGroup = item.groupLabel != null && (index == 0 || items[index - 1].groupLabel != item.groupLabel); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (showGroup) Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0), child: Text(item.groupLabel!, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))), ListTile(title: Text(item.label), trailing: item.value == widget.selected ? const Icon(Icons.check_rounded, color: LightModeColors.lightPrimary) : null, onTap: () => context.pop(item.value))]); })),
      ])),
    );
  }
}