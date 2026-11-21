import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_search_bar.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_widgets.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';

class DogSearchPage extends ConsumerStatefulWidget {
  const DogSearchPage({super.key});
  @override
  ConsumerState<DogSearchPage> createState() => _DogSearchPageState();
}

class _DogSearchPageState extends ConsumerState<DogSearchPage> {
  final controller = TextEditingController();
  Timer? debounce;
  List<DogSearchResult> results = const [];
  String? breedId, regionId;
  String order = 'trials';
  bool loading = false, hasMore = true;
  String? errorKey;
  int offset = 0;
  @override
  void initState() { super.initState(); regionId = ref.read(huntingContextProvider).regionId; WidgetsBinding.instance.addPostFrameCallback((_) => _search(reset: true)); }
  @override
  void dispose() { debounce?.cancel(); controller.dispose(); super.dispose(); }
  void _changed(String _) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 400), () => _search(reset: true)); }
  Future<void> _search({required bool reset}) async {
    if (loading) return;
    setState(() { loading = true; errorKey = null; if (reset) { offset = 0; results = const []; } });
    try {
      final page = await ref.read(dogsRepositoryProvider).search(query: controller.text, breedId: breedId, offset: offset);
      final filtered = regionId == null ? page : page.where((item) => item.regionName != null && _regionName(regionId!) == item.regionName).toList();
      final sorted = [...filtered]..sort((a, b) => order == 'trials' ? b.dog.trialCount.compareTo(a.dog.trialCount) : b.dog.outingCount.compareTo(a.dog.outingCount));
      if (mounted) setState(() { results = reset ? sorted : [...results, ...sorted]; offset += page.length; hasMore = page.length == 30; });
    } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); }
    finally { if (mounted) setState(() => loading = false); }
  }
  String _regionName(String id) { final settings = ref.read(userSettingsProvider); final regions = settings.countryCode == null ? const [] : ref.read(regionsProvider(settings.countryCode!)).value ?? const []; return regions.where((item) => item.id == id).firstOrNull?.name ?? ''; }
  @override
  Widget build(BuildContext context) {
    final breeds = ref.watch(dogBreedsProvider).value ?? const <DogBreed>[];
    final settings = ref.watch(userSettingsProvider);
    final regions = settings.countryCode == null ? const [] : ref.watch(regionsProvider(settings.countryCode!)).value ?? const [];
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg), sliver: SliverList.list(children: [
      HBPageHeader(title: 'dogs.search.title'.tr()), const SizedBox(height: AppSpacing.md), HBListSearchBar(controller: controller, hint: 'dogs.search.hint'.tr(), onChanged: _changed), const SizedBox(height: AppSpacing.md), HBCard(child: Column(children: [ LayoutBuilder(builder: (_, constraints) { final fields = [HBSelect<String?>(value: breedId, options: [HBSelectOption<String?>(value: null, label: 'dogs.search.all_breeds'.tr()), for (final breed in breeds) HBSelectOption<String?>(value: breed.id, label: breed.localizedName(context.locale.languageCode))], onChanged: (value) { setState(() => breedId = value); _search(reset: true); }), HBSelect<String?>(value: regionId, options: [HBSelectOption<String?>(value: null, label: 'dogs.search.all_regions'.tr()), for (final region in regions) HBSelectOption<String?>(value: region.id, label: region.name)], onChanged: (value) { setState(() => regionId = value); _search(reset: true); }), HBSelect<String>(value: order, options: [HBSelectOption(value: 'trials', label: 'dogs.search.order_trials'.tr()), HBSelectOption(value: 'outings', label: 'dogs.search.order_outings'.tr())], onChanged: (value) { if (value == null) return; setState(() => order = value); _search(reset: true); })]; return constraints.maxWidth < 640 ? Column(children: [for (var index = 0; index < fields.length; index++) Padding(padding: EdgeInsets.only(bottom: index == fields.length - 1 ? 0 : AppSpacing.sm), child: fields[index])]) : Row(children: [for (var index = 0; index < fields.length; index++) Expanded(child: Padding(padding: EdgeInsets.only(right: index == fields.length - 1 ? 0 : AppSpacing.sm), child: fields[index]))]); })])), const SizedBox(height: AppSpacing.md),
      if (loading && results.isEmpty) const HBListSkeleton(count: 4) else if (errorKey != null) HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'dogs.error_title'.tr(), message: errorKey!.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => _search(reset: true)))) else if (results.isEmpty) HBCard(child: HBEmptyState(icon: Icons.search_off_rounded, title: 'dogs.search.empty'.tr(), message: 'dogs.search.empty_message'.tr())) else ...[for (var index = 0; index < results.length; index++) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: DogSearchCard(result: results[index])), if (hasMore) HBButton.secondary(label: 'dogs.search.load_more'.tr(), onPressed: loading ? null : () => _search(reset: false), isLoading: loading)],
    ]))]));
  }
}

class DogSearchCard extends StatelessWidget {
  final DogSearchResult result;
  const DogSearchCard({super.key, required this.result});
  @override
  Widget build(BuildContext context) => Column(children: [DogProfileCard(dog: result.dog, horizontal: true), Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0), child: InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(result.owner.username)), child: Row(children: [HBAvatar(name: result.owner.displayName, imageUrl: result.owner.avatarUrl, size: 28), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(result.owner.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)), if (result.regionName != null) Text(result.regionName!, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])))]);
}