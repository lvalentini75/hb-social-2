import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';

class DogTagSelector extends StatefulWidget {
  final List<Dog> dogs;
  final Set<String> selectedIds;
  const DogTagSelector({super.key, required this.dogs, required this.selectedIds});
  @override
  State<DogTagSelector> createState() => _DogTagSelectorState();
}

class _DogTagSelectorState extends State<DogTagSelector> {
  late final Set<String> selected = {...widget.selectedIds};
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('dogs.tags.title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), if (widget.dogs.isEmpty) HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.tags.no_dogs'.tr(), message: 'dogs.tags.no_dogs_message'.tr()) else Flexible(child: ListView(shrinkWrap: true, children: [for (final dog in widget.dogs) CheckboxListTile(value: selected.contains(dog.id), onChanged: (value) => setState(() { if (value == true) { selected.add(dog.id); } else { selected.remove(dog.id); } }), secondary: HBAvatar(name: dog.name, imageUrl: dog.avatarUrl, size: 36), title: Text(dog.name))])), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'dogs.tags.confirm'.tr(), onPressed: () => context.pop(selected))])));
}