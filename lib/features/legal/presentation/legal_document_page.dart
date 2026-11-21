import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/legal/providers/legal_providers.dart';
import 'package:hb_social/core/services/seo_service.dart';
import 'package:intl/intl.dart';

class LegalDocumentPage extends ConsumerWidget {
  final String kind;
  const LegalDocumentPage({super.key, required this.kind});
  @override Widget build(BuildContext context, WidgetRef ref) => ColoredBox(color: LightModeColors.lightBackground, child: SafeArea(child: ref.watch(legalDocumentProvider((kind: kind, locale: context.locale.languageCode))).when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => Center(child: HBEmptyState(icon: Icons.gavel_rounded, title: 'legal.unavailable.title'.tr(), message: 'legal.unavailable.message'.tr(), action: HBButton.secondary(label: 'common.back'.tr(), onPressed: () => context.pop()))),
    data: (document) { SeoService.update(title: '${document.title} - HB Social', description: document.summary ?? 'seo.legal_description'.tr(), path: '/legal/${document.kind}'); return CustomScrollView(slivers: [SliverAppBar(backgroundColor: LightModeColors.surface, pinned: true, leading: IconButton(tooltip: 'a11y.back'.tr(), onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'), icon: const Icon(Icons.arrow_back_rounded)), title: Text(document.title)), SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('legal.version'.tr(namedArgs: {'version': '${document.version}'}), style: context.textStyles.bodySmall), if (document.publishedAt != null) Text(DateFormat.yMMMMd(context.locale.toString()).format(document.publishedAt!.toLocal()), style: context.textStyles.bodySmall), const SizedBox(height: AppSpacing.lg), MarkdownBody(data: document.bodyMarkdown, selectable: true)])))))]); },
  )));
}

class LegalInformationPage extends ConsumerWidget {
  const LegalInformationPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ColoredBox(color: LightModeColors.lightBackground, child: SafeArea(child: ref.watch(currentLegalDocumentsProvider(context.locale.languageCode)).when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => Center(child: Text('legal.unavailable.message'.tr())), data: (items) => CustomScrollView(slivers: [SliverAppBar(backgroundColor: LightModeColors.surface, title: Text('legal.information.title'.tr()), leading: IconButton(tooltip: 'a11y.back'.tr(), onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded))), SliverList.builder(itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; return ListTile(minTileHeight: 56, title: Text(item.title), subtitle: Text('legal.version'.tr(namedArgs: {'version': '${item.version}'})), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/legal/${item.kind}')); })]))));
}