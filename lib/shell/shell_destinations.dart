import 'package:flutter/material.dart';
import 'package:hb_social/core/router/app_router.dart';

/// A single navigation destination of the shell, bound to a branch of the
/// [StatefulShellRoute] by its index.
class ShellDestination {
  final String path;
  final IconData icon;
  final String labelKey;

  const ShellDestination({required this.path, required this.icon, required this.labelKey});

  int get branchIndex => AppRoutes.branchIndexOf(path)!;
}

/// PD4 main block of the web navigation panel. Only destinations that already
/// own a route appear here ("Segnalibri" has no route yet, so it is omitted).
final List<ShellDestination> sidebarMainDestinations = [
  const ShellDestination(path: AppRoutes.home, icon: Icons.home_rounded, labelKey: 'nav.home'),
  const ShellDestination(path: AppRoutes.search, icon: Icons.explore_outlined, labelKey: 'nav.explore'),
  const ShellDestination(path: AppRoutes.groups, icon: Icons.groups_2_outlined, labelKey: 'nav.groups'),
  const ShellDestination(path: AppRoutes.forum, icon: Icons.forum_outlined, labelKey: 'nav.forum'),
  const ShellDestination(path: AppRoutes.pages, icon: Icons.article_outlined, labelKey: 'nav.pages_nav'),
  const ShellDestination(path: AppRoutes.marketplace, icon: Icons.storefront_outlined, labelKey: 'nav.marketplace'),
  ShellDestination(path: AppRoutes.events, icon: Icons.event_outlined, labelKey: 'nav.events'),
  const ShellDestination(path: AppRoutes.messages, icon: Icons.chat_bubble_outline_rounded, labelKey: 'nav.messages'),
  const ShellDestination(path: AppRoutes.notifications, icon: Icons.notifications_none_rounded, labelKey: 'nav.notifications'),
  const ShellDestination(path: AppRoutes.profile, icon: Icons.person_outline_rounded, labelKey: 'nav.profile'),
];

/// The "Strumenti di caccia" section links directly to each hunting tool.
const List<ShellDestination> sidebarHuntingDestinations = [
  ShellDestination(path: AppRoutes.huntingDiary, icon: Icons.menu_book_outlined, labelKey: 'sidebar.hunting_diary'),
  ShellDestination(path: AppRoutes.huntingMap, icon: Icons.map_outlined, labelKey: 'sidebar.hunting_map'),
  ShellDestination(path: AppRoutes.sightings, icon: Icons.visibility_outlined, labelKey: 'sightings.nav'),
  ShellDestination(path: AppRoutes.huntingDogs, icon: Icons.pets_outlined, labelKey: 'sidebar.hunting_dogs'),
  ShellDestination(path: AppRoutes.huntingZone, icon: Icons.terrain_outlined, labelKey: 'sidebar.hunting_zones'),
  ShellDestination(path: AppRoutes.huntingCalendar, icon: Icons.calendar_month_outlined, labelKey: 'sidebar.hunting_calendar'),
];

/// The 2 route destinations shown on each side of the mobile bottom bar's
/// central create FAB.
const List<ShellDestination> bottomNavLeadingDestinations = [
  ShellDestination(path: AppRoutes.home, icon: Icons.home_rounded, labelKey: 'nav.home'),
  ShellDestination(path: AppRoutes.search, icon: Icons.search_rounded, labelKey: 'nav.search'),
];

const ShellDestination bottomNavTrailingDestination = ShellDestination(
  path: AppRoutes.notifications,
  icon: Icons.notifications_none_rounded,
  labelKey: 'nav.notifications',
);
