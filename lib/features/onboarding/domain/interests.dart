import 'package:flutter/material.dart';

class OnboardingInterest {
  final String slug;
  final String translationKey;
  final IconData icon;

  const OnboardingInterest({required this.slug, required this.translationKey, required this.icon});
}

const onboardingInterests = [
  OnboardingInterest(slug: 'cinghiale', translationKey: 'onboarding.interests.cinghiale', icon: Icons.pets_outlined),
  OnboardingInterest(slug: 'ungulati', translationKey: 'onboarding.interests.ungulati', icon: Icons.landscape_outlined),
  OnboardingInterest(slug: 'beccaccia', translationKey: 'onboarding.interests.beccaccia', icon: Icons.forest_outlined),
  OnboardingInterest(slug: 'migratoria', translationKey: 'onboarding.interests.migratoria', icon: Icons.air_outlined),
  OnboardingInterest(slug: 'acquatici', translationKey: 'onboarding.interests.acquatici', icon: Icons.water_outlined),
  OnboardingInterest(slug: 'stanziale', translationKey: 'onboarding.interests.stanziale', icon: Icons.grass_outlined),
  OnboardingInterest(slug: 'cinofilia', translationKey: 'onboarding.interests.cinofilia', icon: Icons.favorite_outline),
  OnboardingInterest(slug: 'tiro', translationKey: 'onboarding.interests.tiro', icon: Icons.gps_fixed_outlined),
  OnboardingInterest(slug: 'armi_ottiche', translationKey: 'onboarding.interests.armi_ottiche', icon: Icons.center_focus_strong_outlined),
  OnboardingInterest(slug: 'cucina_selvaggina', translationKey: 'onboarding.interests.cucina_selvaggina', icon: Icons.restaurant_outlined),
  OnboardingInterest(slug: 'normativa', translationKey: 'onboarding.interests.normativa', icon: Icons.gavel_outlined),
  OnboardingInterest(slug: 'fotografia_natura', translationKey: 'onboarding.interests.fotografia_natura', icon: Icons.photo_camera_outlined),
];