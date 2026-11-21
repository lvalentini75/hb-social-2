import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/diary/domain/diary_season_stats.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/diary/presentation/diary_file_download.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class DiaryExportData {
  final DiarySeasonStats stats;
  final List<Outing> outings;
  final UserProfile profile;
  final String regionName;
  final Map<String, String> speciesNames;
  final String locale;
  const DiaryExportData({required this.stats, required this.outings, required this.profile, required this.regionName, required this.speciesNames, required this.locale});
}

class DiaryExportService {
  static String safeSeason(String value) => value.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '-');

  static Future<Uint8List> buildPdf(DiaryExportData data) async {
    final document = pw.Document();
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final date = DateFormat.yMMMMd(data.locale).format(DateTime.now());
    String speciesName(DiarySpeciesStat item) => data.speciesNames[item.speciesId] ?? item.nameIt.ifEmpty(item.scientificName);
    String outingSpecies(Outing item) => item.species.map((row) => '${data.speciesNames[row.speciesId] ?? row.name}: ${row.harvestCount}').join(', ');
    String outingDogs(Outing item) => item.dogs.map((dog) => dog.name).join(', ');
    String location(Outing item) => [item.zoneName, item.municipalityName, item.unitName].whereType<String>().where((value) => value.isNotEmpty).join(' / ');
    String weather(Outing item) => item.weather == null ? '' : 'diary.export.weather_short'.tr(namedArgs: {'temperature': item.weather!.temperature?.toStringAsFixed(0) ?? '-', 'rain': item.weather!.precipitation?.toStringAsFixed(1) ?? '-'});
    String duration(Outing item) { final minutes = item.durationMin ?? item.endedAt?.difference(item.startedAt).inMinutes; return minutes == null ? '' : '${minutes ~/ 60}h ${minutes.remainder(60)}m'; }
    final green = PdfColor.fromHex('#225E34');

    document.addPage(pw.Page(pageFormat: PdfPageFormat.a4, theme: theme, build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Spacer(), pw.Text('HB Social', style: pw.TextStyle(font: bold, fontSize: 22, color: green)), pw.SizedBox(height: 18), pw.Text('diary.export.book_title'.tr(namedArgs: {'season': data.stats.seasonLabel}), style: pw.TextStyle(font: bold, fontSize: 34)), pw.SizedBox(height: 36), pw.Text(data.profile.displayName, style: pw.TextStyle(font: bold, fontSize: 18)), pw.Text('@${data.profile.username}'), if (data.regionName.isNotEmpty) pw.Text(data.regionName), pw.Spacer(), pw.Text('diary.export.generated_on'.tr(namedArgs: {'date': date}), style: const pw.TextStyle(fontSize: 12))])));
    document.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, theme: theme, header: (_) => pw.Text('diary.export.summary'.tr(), style: pw.TextStyle(font: bold, color: green)), footer: (context) => _footer(context, bold), build: (_) => [
      pw.SizedBox(height: 12), pw.Wrap(spacing: 12, runSpacing: 12, children: [_pdfKpi('diary.stats.outings'.tr(), '${data.stats.totals.outings}', bold), _pdfKpi('diary.stats.hours'.tr(), data.stats.totals.hours.toStringAsFixed(1), bold), _pdfKpi('diary.stats.harvests'.tr(), '${data.stats.totals.harvests}', bold), _pdfKpi('diary.stats.distance'.tr(), (data.stats.totals.distanceM / 1000).toStringAsFixed(1), bold)]),
      pw.SizedBox(height: 18), pw.Text('diary.stats.species'.tr(), style: pw.TextStyle(font: bold, fontSize: 15)), pw.SizedBox(height: 6), pw.TableHelper.fromTextArray(headers: ['diary.export.species'.tr(), 'diary.stats.harvested'.tr(), 'diary.stats.seen'.tr(), 'diary.stats.shots'.tr(), 'diary.stats.outings'.tr()], data: [for (final item in data.stats.bySpecies) [speciesName(item), '${item.harvests}', '${item.seen}', '${item.shots}', '${item.outings}']], headerStyle: pw.TextStyle(font: bold), headerDecoration: pw.BoxDecoration(color: PdfColors.grey200), cellStyle: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 18), pw.Text('diary.stats.by_month'.tr(), style: pw.TextStyle(font: bold, fontSize: 15)), pw.SizedBox(height: 6), pw.TableHelper.fromTextArray(headers: ['diary.export.month'.tr(), 'diary.stats.outings'.tr(), 'diary.stats.harvests'.tr(), 'diary.stats.hours'.tr()], data: [for (final item in data.stats.byMonth) [item.key, '${item.outings}', '${item.harvests}', item.hours.toStringAsFixed(1)]], headerStyle: pw.TextStyle(font: bold), cellStyle: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 18), _monthlyBars(data.stats.byMonth, bold, green),
    ]));
    document.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape, theme: theme, header: (_) => pw.Text('diary.export.outings_title'.tr(namedArgs: {'season': data.stats.seasonLabel}), style: pw.TextStyle(font: bold, color: green)), footer: (context) => _footer(context, bold), build: (_) => [pw.TableHelper.fromTextArray(headers: ['diary.export.date'.tr(), 'diary.export.time_duration'.tr(), 'diary.export.place'.tr(), 'diary.export.unit'.tr(), 'diary.export.method'.tr(), 'diary.export.species'.tr(), 'diary.export.dogs'.tr(), 'diary.export.weather'.tr(), 'diary.export.notes'.tr()], data: [for (final item in data.outings) [DateFormat.yMd(data.locale).format(item.startedAt.toLocal()), '${DateFormat.Hm(data.locale).format(item.startedAt.toLocal())} ${duration(item)}', location(item), item.unitName ?? '', item.method.labelKey.tr(), outingSpecies(item), outingDogs(item), weather(item), _truncate(item.notes, 120)]], headerStyle: pw.TextStyle(font: bold, fontSize: 7), cellStyle: const pw.TextStyle(fontSize: 6.5), cellPadding: const pw.EdgeInsets.all(3))]));
    return document.save();
  }

  static pw.Widget _pdfKpi(String label, String value, pw.Font bold) => pw.Container(width: 118, padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(label, style: const pw.TextStyle(fontSize: 9)), pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 20))]));
  static pw.Widget _monthlyBars(List<DiaryPeriodStat> items, pw.Font bold, PdfColor color) { final max = items.fold<int>(0, (value, item) => item.outings > value ? item.outings : value); return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('diary.export.month_chart'.tr(), style: pw.TextStyle(font: bold)), pw.SizedBox(height: 8), for (final item in items) pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: pw.Row(children: [pw.SizedBox(width: 52, child: pw.Text(item.key, style: const pw.TextStyle(fontSize: 8))), pw.Container(height: 9, width: max == 0 ? 0 : 300 * item.outings / max, color: color), pw.SizedBox(width: 5), pw.Text('${item.outings}', style: const pw.TextStyle(fontSize: 8))]))]); }
  static pw.Widget _footer(pw.Context context, pw.Font bold) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('diary.export.footer'.tr(), style: const pw.TextStyle(fontSize: 8)), pw.Text('${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(font: bold, fontSize: 8))]);
  static String _truncate(String? value, int max) => value == null ? '' : value.length <= max ? value : '${value.substring(0, max - 1)}...';

  static Uint8List buildCsv(DiaryExportData data) {
    String quote(Object? value) => '"${(value ?? '').toString().replaceAll('"', '""')}"';
    final rows = <List<Object?>>[
      ['diary.export.date'.tr(), 'diary.export.start'.tr(), 'diary.export.end'.tr(), 'diary.export.duration'.tr(), 'diary.export.place'.tr(), 'diary.export.unit'.tr(), 'diary.export.method'.tr(), 'diary.export.species'.tr(), 'diary.export.dogs'.tr(), 'diary.export.weather'.tr(), 'diary.export.notes'.tr()],
      for (final item in data.outings) [DateFormat('yyyy-MM-dd').format(item.startedAt.toLocal()), DateFormat.Hm(data.locale).format(item.startedAt.toLocal()), item.endedAt == null ? '' : DateFormat.Hm(data.locale).format(item.endedAt!.toLocal()), item.durationMin ?? item.endedAt?.difference(item.startedAt).inMinutes ?? '', [item.zoneName, item.municipalityName].whereType<String>().join(' / '), item.unitName ?? '', item.method.labelKey.tr(), item.species.map((row) => '${data.speciesNames[row.speciesId] ?? row.name}:${row.harvestCount}').join(', '), item.dogs.map((dog) => dog.name).join(', '), item.weather == null ? '' : '${item.weather!.temperature?.toStringAsFixed(0) ?? ''}C / ${item.weather!.precipitation?.toStringAsFixed(1) ?? ''}mm', item.notes ?? ''],
    ];
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(rows.map((row) => row.map(quote).join(';')).join('\r\n'))]);
  }

  static Future<void> shareCsv(DiaryExportData data) async {
    final filename = 'hb-diario-${safeSeason(data.stats.seasonLabel)}.csv';
    if (kIsWeb) {
      downloadDiaryFile(buildCsv(data), filename, 'text/csv;charset=utf-8');
      return;
    }
    await Share.shareXFiles([XFile.fromData(buildCsv(data), mimeType: 'text/csv', name: filename)], subject: 'diary.export.csv'.tr(), fileNameOverrides: [filename]);
  }

  static Future<void> sharePdf(DiaryExportData data) async {
    final filename = 'hb-libretto-${safeSeason(data.stats.seasonLabel)}.pdf';
    final bytes = await buildPdf(data);
    if (kIsWeb) {
      downloadDiaryFile(bytes, filename, 'application/pdf');
      return;
    }
    await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'application/pdf', name: filename)], subject: 'diary.export.book_title'.tr(namedArgs: {'season': data.stats.seasonLabel}), fileNameOverrides: [filename]);
  }
}

class DiaryPdfPreview extends StatelessWidget {
  final DiaryExportData data;
  const DiaryPdfPreview({super.key, required this.data});
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(child: Column(children: [Container(height: 64, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), color: LightModeColors.lightSurface, child: Row(children: [Expanded(child: Text('diary.export.preview_title'.tr(), style: context.textStyles.titleLarge)), IconButton(onPressed: () => DiaryExportService.sharePdf(data), icon: const Icon(Icons.share_outlined), tooltip: 'common.share'.tr()), IconButton(onPressed: context.pop, icon: const Icon(Icons.close_rounded), tooltip: 'diary.actions.close'.tr())])), Expanded(child: PdfPreview(build: (_) => DiaryExportService.buildPdf(data), pdfFileName: 'hb-libretto-${DiaryExportService.safeSeason(data.stats.seasonLabel)}.pdf', allowPrinting: true, allowSharing: false, canChangeOrientation: false, canChangePageFormat: false))]));
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}