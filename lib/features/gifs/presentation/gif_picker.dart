import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/gifs/domain/gif_result.dart';
import 'package:hb_social/features/gifs/providers/gifs_providers.dart';

Future<GifResult?> showGifPicker(BuildContext context) => showModalBottomSheet<GifResult>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => const FractionallySizedBox(heightFactor: .82, child: GifPicker()));

class GifPicker extends ConsumerStatefulWidget {
  const GifPicker({super.key});
  @override ConsumerState<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends ConsumerState<GifPicker> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  Timer? debounce;
  List<GifResult> items = const [];
  int? next;
  bool loading = true;
  bool loadingMore = false;
  String? error;

  @override void initState() { super.initState(); scrollController.addListener(_scroll); _load(reset: true); }
  @override void dispose() { debounce?.cancel(); controller.dispose(); scrollController.dispose(); super.dispose(); }
  void _scroll() { if (scrollController.hasClients && scrollController.position.extentAfter < 400 && next != null && !loadingMore) _load(); }
  void _search(String value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 400), () => _load(reset: true)); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() { loading = true; error = null; }); else setState(() => loadingMore = true);
    try {
      final page = await ref.read(gifsRepositoryProvider).load(locale: context.locale.languageCode, query: controller.text, offset: reset ? 0 : next ?? 0);
      if (mounted) setState(() { items = reset ? page.results : [...items, ...page.results]; next = page.next; loading = false; loadingMore = false; });
    } on AppException catch (failure) { if (mounted) setState(() { loading = false; loadingMore = false; error = failure.messageKey; }); }
  }

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
    child: Column(children: [
      Row(children: [Expanded(child: Text('gifs.title'.tr(), style: context.textStyles.titleLarge)), HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop())]),
      const SizedBox(height: AppSpacing.sm),
      HBInput(controller: controller, hint: 'gifs.search'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: _search),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: _content(context)),
      const SizedBox(height: AppSpacing.sm),
      Text('gifs.powered_by'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.textSecondary)),
    ]),
  );

  Widget _content(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return HBEmptyState(icon: Icons.gif_box_outlined, title: 'gifs.error_title'.tr(), message: error!.tr(), action: error == 'gifs.errors.not_configured' ? null : HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => _load(reset: true)));
    if (items.isEmpty) return HBEmptyState(icon: Icons.gif_box_outlined, title: 'gifs.empty_title'.tr(), message: 'gifs.empty_message'.tr());
    return GridView.builder(
      controller: scrollController,
      itemCount: items.length + (loadingMore ? 1 : 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 3 : 2, crossAxisSpacing: AppSpacing.xs, mainAxisSpacing: AppSpacing.xs),
      itemBuilder: (_, index) {
        if (index == items.length) return const Center(child: CircularProgressIndicator());
        final gif = items[index];
        return InkWell(onTap: () => context.pop(gif), child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(gif.preview, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.broken_image_outlined)))));
      },
    );
  }
}

class GifImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  const GifImage({super.key, required this.url, this.width, this.height});
  @override Widget build(BuildContext context) => InkWell(onTap: () => showDialog<void>(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: Stack(children: [InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)), Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop(), backgroundColor: LightModeColors.overlayStrong, foregroundColor: Colors.white))]))), child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: Image.network(url, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 120, child: ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.broken_image_outlined))))));
}