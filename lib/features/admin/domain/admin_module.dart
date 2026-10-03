import 'package:flutter/material.dart';

class AdminModule {
  final String slug;
  final String titleKey;
  final String descriptionKey;
  final String phase;
  final IconData icon;

  const AdminModule({required this.slug, required this.titleKey, required this.descriptionKey, required this.phase, required this.icon});
}

class AdminModuleSection {
  final String labelKey;
  final List<AdminModule> modules;

  const AdminModuleSection({required this.labelKey, required this.modules});
}

const adminModuleSections = <AdminModuleSection>[
  AdminModuleSection(labelKey: 'admin.sections.overview', modules: [AdminModule(slug: '', titleKey: 'admin.modules.dashboard.title', descriptionKey: 'admin.modules.dashboard.description', phase: 'P05', icon: Icons.dashboard_outlined)]),
  AdminModuleSection(labelKey: 'admin.sections.users', modules: [
    AdminModule(slug: 'users', titleKey: 'admin.modules.users.title', descriptionKey: 'admin.modules.users.description', phase: 'P41', icon: Icons.people_outline),
    AdminModule(slug: 'badges', titleKey: 'admin.modules.badges.title', descriptionKey: 'admin.modules.badges.description', phase: 'P41', icon: Icons.verified_outlined),
    AdminModule(slug: 'roles', titleKey: 'admin.modules.roles.title', descriptionKey: 'admin.modules.roles.description', phase: 'P40', icon: Icons.admin_panel_settings_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.content', modules: [
    AdminModule(slug: 'content', titleKey: 'admin.modules.content.title', descriptionKey: 'admin.modules.content.description', phase: 'P41', icon: Icons.collections_outlined),
    AdminModule(slug: 'communities', titleKey: 'admin.modules.communities.title', descriptionKey: 'admin.modules.communities.description', phase: 'P41', icon: Icons.forum_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.moderation', modules: [
    AdminModule(slug: 'reports', titleKey: 'admin.modules.reports.title', descriptionKey: 'admin.modules.reports.description', phase: 'P41', icon: Icons.report_outlined),
    AdminModule(slug: 'approvals', titleKey: 'admin.modules.approvals.title', descriptionKey: 'admin.modules.approvals.description', phase: 'P42', icon: Icons.approval_outlined),
    AdminModule(slug: 'rules', titleKey: 'admin.modules.rules.title', descriptionKey: 'admin.modules.rules.description', phase: 'P41', icon: Icons.gavel_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.commerce', modules: [
    AdminModule(slug: 'listings', titleKey: 'admin.modules.listings.title', descriptionKey: 'admin.modules.listings.description', phase: 'P42', icon: Icons.storefront_outlined),
    AdminModule(slug: 'orders', titleKey: 'admin.modules.orders.title', descriptionKey: 'admin.modules.orders.description', phase: 'P42', icon: Icons.receipt_long_outlined),
    AdminModule(slug: 'payments', titleKey: 'admin.modules.payments.title', descriptionKey: 'admin.modules.payments.description', phase: 'P42', icon: Icons.payments_outlined),
    AdminModule(slug: 'plans', titleKey: 'admin.modules.plans.title', descriptionKey: 'admin.modules.plans.description', phase: 'P42', icon: Icons.workspace_premium_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.advertising', modules: [
    AdminModule(slug: 'ad-review', titleKey: 'admin.modules.adReview.title', descriptionKey: 'admin.modules.adReview.description', phase: 'P42', icon: Icons.fact_check_outlined),
    AdminModule(slug: 'advertisers', titleKey: 'admin.modules.advertisers.title', descriptionKey: 'admin.modules.advertisers.description', phase: 'P42', icon: Icons.campaign_outlined),
    AdminModule(slug: 'revenue', titleKey: 'admin.modules.revenue.title', descriptionKey: 'admin.modules.revenue.description', phase: 'P42', icon: Icons.query_stats_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.huntingData', modules: [
    AdminModule(slug: 'calendars', titleKey: 'admin.modules.calendars.title', descriptionKey: 'admin.modules.calendars.description', phase: 'P44', icon: Icons.calendar_month_outlined),
    AdminModule(slug: 'maps', titleKey: 'admin.modules.maps.title', descriptionKey: 'admin.modules.maps.description', phase: 'P44', icon: Icons.map_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.platform', modules: [
    AdminModule(slug: 'plugins', titleKey: 'admin.modules.plugins.title', descriptionKey: 'admin.modules.plugins.description', phase: 'P43', icon: Icons.extension_outlined),
    AdminModule(slug: 'localization', titleKey: 'admin.modules.localization.title', descriptionKey: 'admin.modules.localization.description', phase: 'P43', icon: Icons.translate_outlined),
    AdminModule(slug: 'system-notifications', titleKey: 'admin.modules.systemNotifications.title', descriptionKey: 'admin.modules.systemNotifications.description', phase: 'P43', icon: Icons.notifications_active_outlined),
    AdminModule(slug: 'security', titleKey: 'admin.modules.security.title', descriptionKey: 'admin.modules.security.description', phase: 'P40', icon: Icons.security_outlined),
    AdminModule(slug: 'system', titleKey: 'admin.modules.system.title', descriptionKey: 'admin.modules.system.description', phase: 'P43', icon: Icons.settings_suggest_outlined),
    AdminModule(slug: 'support', titleKey: 'admin.modules.support.title', descriptionKey: 'admin.modules.support.description', phase: 'P43', icon: Icons.support_agent_outlined),
  ]),
];

AdminModule? adminModuleForSlug(String slug) {
  for (final section in adminModuleSections) {
    for (final module in section.modules) {
      if (module.slug == slug) return module;
    }
  }
  return null;
}