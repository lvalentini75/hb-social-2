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

/// The main block of the web sidebar (search and notifications live in the
/// header instead; hunting and "mine" destinations have their own sections
/// below, profile lives in the sidebar's top profile card and the account
/// menu).
const List<ShellDestination> sidebarMainDestinations = [
  ShellDestination(path: AppRoutes.home, icon: Icons.home_rounded, labelKey: 'nav.home'),
  ShellDestination(path: AppRoutes.groups, icon: Icons.groups_2_outlined, labelKey: 'nav.groups'),
  ShellDestination(path: AppRoutes.forum, icon: Icons.forum_outlined, labelKey: 'nav.forum'),
  ShellDestination(path: AppRoutes.pages, icon: Icons.article_outlined, labelKey: 'nav.pages'),
  ShellDestination(path: AppRoutes.marketplace, icon: Icons.storefront_outlined, labelKey: 'nav.marketplace'),
  ShellDestination(path: AppRoutes.events, icon: Icons.event_outlined, labelKey: 'nav.events'),
  ShellDestination(path: AppRoutes.messages, icon: Icons.chat_bubble_outline_rounded, labelKey: 'nav.messages'),
];

/// The "A CACCIA" sidebar section links directly to each hunting tool.
const List<ShellDestination> sidebarHuntingDestinations = [
  ShellDestination(path: AppRoutes.huntingDiary, icon: Icons.menu_book_outlined, labelKey: 'sidebar.hunting_diary'),
  ShellDestination(path: AppRoutes.huntingMap, icon: Icons.map_outlined, labelKey: 'sidebar.hunting_map'),
  ShellDestination(path: AppRoutes.huntingDogs, icon: Icons.pets_outlined, labelKey: 'sidebar.hunting_dogs'),
  ShellDestination(path: AppRoutes.huntingCalendar, icon: Icons.calendar_month_outlined, labelKey: 'sidebar.hunting_calendar'),
];

/// The "I MIEI" sidebar section, without counters until there is real data.
const List<ShellDestination> sidebarMineDestinations = [
  ShellDestination(path: AppRoutes.groups, icon: Icons.groups_2_outlined, labelKey: 'sidebar.my_groups'),
  ShellDestination(path: AppRoutes.marketplace, icon: Icons.storefront_outlined, labelKey: 'sidebar.my_listings'),
  ShellDestination(path: AppRoutes.events, icon: Icons.event_outlined, labelKey: 'sidebar.my_events'),
];

/// The 2 route destinations shown on each side of the mobile bottom bar's
/// central create FAB. The 5th slot ("Altro") opens a bottom sheet instead
/// of a branch, so it is not a [ShellDestination].
const List<ShellDestination> bottomNavLeadingDestinations = [
  ShellDestination(path: AppRoutes.home, icon: Icons.home_rounded, labelKey: 'nav.home'),
  ShellDestination(path: AppRoutes.groups, icon: Icons.groups_2_outlined, labelKey: 'nav.groups'),
];

const ShellDestination bottomNavTrailingDestination = ShellDestination(
  path: AppRoutes.marketplace,
  icon: Icons.storefront_outlined,
  labelKey: 'nav.marketplace',
);
