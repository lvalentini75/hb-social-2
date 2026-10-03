import 'package:flutter/material.dart';

/// A selectable hunting discipline shown as a chip in onboarding step 2.
class HuntingInterest {
  final String id;
  final String translationKey;
  final IconData icon;

  const HuntingInterest({required this.id, required this.translationKey, required this.icon});
}

const List<HuntingInterest> huntingInterests = [
  HuntingInterest(id: 'beccaccia', translationKey: 'onboarding.interest_beccaccia', icon: Icons.forest_outlined),
  HuntingInterest(id: 'cinghiale', translationKey: 'onboarding.interest_cinghiale', icon: Icons.pets_outlined),
  HuntingInterest(id: 'ungulati', translationKey: 'onboarding.interest_ungulati', icon: Icons.landscape_outlined),
  HuntingInterest(id: 'migratoria', translationKey: 'onboarding.interest_migratoria', icon: Icons.air_outlined),
  HuntingInterest(id: 'acquatici', translationKey: 'onboarding.interest_acquatici', icon: Icons.water_outlined),
  HuntingInterest(id: 'cinofilia', translationKey: 'onboarding.interest_cinofilia', icon: Icons.favorite_outline),
  HuntingInterest(id: 'tiro', translationKey: 'onboarding.interest_tiro', icon: Icons.gps_fixed_outlined),
  HuntingInterest(id: 'selezione', translationKey: 'onboarding.interest_selezione', icon: Icons.filter_center_focus_outlined),
];
