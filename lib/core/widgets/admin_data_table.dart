import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';

/// Dense admin table with a shared empty and four-row loading treatment.
class AdminDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final String emptyMessage;
  final bool isLoading;
  final List<double>? columnWidths;
  final List<VoidCallback?> rowCallbacks;
  final int compactColumnCount;

  const AdminDataTable({super.key, required this.headers, required this.rows, required this.emptyMessage, this.isLoading = false, this.columnWidths, this.rowCallbacks = const [], this.compactColumnCount = 3});

  @override
  Widget build(BuildContext context) {
    final visibleCount = MediaQuery.sizeOf(context).width < 900 ? compactColumnCount.clamp(1, headers.length) : headers.length;
    final visibleHeaders = headers.take(visibleCount).toList();
    final visibleRows = rows.map((row) => row.take(visibleCount).toList()).toList();
    final widths = (columnWidths ?? List<double>.filled(headers.length, 148)).take(visibleCount).toList();
    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth < constraints.maxWidth ? constraints.maxWidth : totalWidth,
          child: Column(
            children: [
              SizedBox(
                height: 36,
               child: Row(children: [for (var i = 0; i < visibleHeaders.length; i++) SizedBox(width: totalWidth < constraints.maxWidth ? constraints.maxWidth / visibleHeaders.length : widths[i], child: AdminTableHeader(label: visibleHeaders[i]))]),
              ),
              const Divider(),
              if (isLoading)
                 for (var row = 0; row < 4; row++) AdminTableSkeletonRow(columnCount: visibleHeaders.length, widths: widths, availableWidth: constraints.maxWidth)
               else if (visibleRows.isEmpty)
                SizedBox(height: 96, child: Center(child: Text(emptyMessage, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))))
              else
                 for (var index = 0; index < visibleRows.length; index++) AdminTableRow(cells: visibleRows[index], widths: widths, availableWidth: constraints.maxWidth, onTap: index < rowCallbacks.length ? rowCallbacks[index] : null),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminTableHeader extends StatelessWidget {
  final String label;

  const AdminTableHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: Align(alignment: Alignment.centerLeft, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightTextTertiary).copyWith(fontWeight: FontWeight.w600))),
  );
}

class AdminTableRow extends StatelessWidget {
  final List<Widget> cells;
  final List<double> widths;
  final double availableWidth;
  final VoidCallback? onTap;

  const AdminTableRow({super.key, required this.cells, required this.widths, required this.availableWidth, this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width);
    return InkWell(
      onTap: onTap,
      child: Container(height: 52, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LightModeColors.lightDivider))), child: Row(children: [for (var i = 0; i < cells.length; i++) SizedBox(width: totalWidth < availableWidth ? availableWidth / cells.length : widths[i], child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Align(alignment: Alignment.centerLeft, child: cells[i])))])),
    );
  }
}

class AdminTableSkeletonRow extends StatelessWidget {
  final int columnCount;
  final List<double> widths;
  final double availableWidth;

  const AdminTableSkeletonRow({super.key, required this.columnCount, required this.widths, required this.availableWidth});

  @override
  Widget build(BuildContext context) {
    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width);
    return SizedBox(
      height: 44,
      child: Row(children: [for (var i = 0; i < columnCount; i++) SizedBox(width: totalWidth < availableWidth ? availableWidth / columnCount : widths[i], child: const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: HBSkeleton(height: 12)))]),
    );
  }
}