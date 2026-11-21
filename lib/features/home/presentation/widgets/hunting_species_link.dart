import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/features/hunting/presentation/hunting_species_page.dart';

Future<void> openHuntingSpecies(BuildContext context, String speciesId) async {
  if (MediaQuery.sizeOf(context).width < 700) {
    await showModalBottomSheet<void>(context: context, useRootNavigator: true, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: HuntingSpeciesPanel(speciesId: speciesId)));
  } else {
    context.push(AppRoutes.huntingSpeciesPath(speciesId));
  }
}