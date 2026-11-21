import 'package:flutter/material.dart';

class AdminModule {
  final String slug;
  final String permissionSlug;
  final String titleKey;
  final String descriptionKey;
  final String phase;
  final IconData icon;

  const AdminModule({required this.slug, String? permissionSlug, required this.titleKey, required this.descriptionKey, required this.phase, required this.icon}) : permissionSlug = permissionSlug ?? slug;
}

class AdminModuleSection {
  final String labelKey;
  final List<AdminModule> modules;

  const AdminModuleSection({required this.labelKey, required this.modules});
}

const adminModuleSections = <AdminModuleSection>[
  AdminModuleSection(labelKey: 'admin.sections.overview', modules: [AdminModule(slug: '', permissionSlug: 'dashboard', titleKey: 'admin.modules.dashboard.title', descriptionKey: 'admin.modules.dashboard.description', phase: 'P05', icon: Icons.dashboard_outlined)]),
  AdminModuleSection(labelKey: 'admin.sections.users', modules: [
    AdminModule(slug: 'users', titleKey: 'admin.modules.users.title', descriptionKey: 'admin.modules.users.description', phase: 'P41', icon: Icons.people_outline),
    AdminModule(slug: 'badges', titleKey: 'admin.modules.badges.title', descriptionKey: 'admin.modules.badges.description', phase: 'P41', icon: Icons.verified_outlined),
    AdminModule(slug: 'roles', titleKey: 'admin.modules.roles.title', descriptionKey: 'admin.modules.roles.description', phase: 'P40', icon: Icons.admin_panel_settings_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.content', modules: [
    AdminModule(slug: 'content', titleKey: 'admin.modules.content.title', descriptionKey: 'admin.modules.content.description', phase: 'P41', icon: Icons.collections_outlined),
    AdminModule(slug: 'live', permissionSlug: 'content', titleKey: 'admin_live.title', descriptionKey: 'admin_live.subtitle', phase: 'P46', icon: Icons.live_tv_outlined),
    AdminModule(slug: 'communities', titleKey: 'admin.modules.communities.title', descriptionKey: 'admin.modules.communities.description', phase: 'P41', icon: Icons.forum_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.moderation', modules: [
    AdminModule(slug: 'reports', titleKey: 'admin.modules.reports.title', descriptionKey: 'admin.modules.reports.description', phase: 'P41', icon: Icons.report_outlined),
    AdminModule(slug: 'approvals', titleKey: 'admin.modules.approvals.title', descriptionKey: 'admin.modules.approvals.description', phase: 'P42', icon: Icons.approval_outlined),
    AdminModule(slug: 'rules', titleKey: 'admin.modules.rules.title', descriptionKey: 'admin.modules.rules.description', phase: 'P41', icon: Icons.gavel_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.commerce', modules: [
    AdminModule(slug: 'listings', titleKey: 'admin.modules.listings.title', descriptionKey: 'admin.modules.listings.description', phase: 'P42', icon: Icons.storefront_outlined),
    AdminModule(slug: 'orders', titleKey: 'admin.modules.orders.title', descriptionKey: 'admin.modules.orders.description', phase: 'P21', icon: Icons.receipt_long_outlined),
    AdminModule(slug: 'finance', permissionSlug: 'payments', titleKey: 'admin.finance.title', descriptionKey: 'admin.finance.subtitle', phase: 'P34', icon: Icons.payments_outlined),
    AdminModule(slug: 'plans', titleKey: 'admin.modules.plans.title', descriptionKey: 'admin.modules.plans.description', phase: 'P35', icon: Icons.workspace_premium_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.advertising', modules: [
    AdminModule(slug: 'ads', permissionSlug: 'ad-review', titleKey: 'admin.modules.adReview.title', descriptionKey: 'admin.modules.adReview.description', phase: 'P37', icon: Icons.fact_check_outlined),
    AdminModule(slug: 'advertisers', titleKey: 'admin.modules.advertisers.title', descriptionKey: 'admin.modules.advertisers.description', phase: 'P37', icon: Icons.campaign_outlined),
    AdminModule(slug: 'revenue', titleKey: 'admin.modules.revenue.title', descriptionKey: 'admin.modules.revenue.description', phase: 'P39', icon: Icons.query_stats_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.huntingData', modules: [
    AdminModule(slug: 'hunting', permissionSlug: 'calendars', titleKey: 'admin.hunting.title', descriptionKey: 'admin.hunting.subtitle', phase: 'P24', icon: Icons.eco_outlined),
    AdminModule(slug: 'maps', titleKey: 'admin.modules.maps.title', descriptionKey: 'admin.modules.maps.description', phase: 'P28', icon: Icons.map_outlined),
  ]),
  AdminModuleSection(labelKey: 'admin.sections.platform', modules: [
    AdminModule(slug: 'plugins', titleKey: 'admin.modules.plugins.title', descriptionKey: 'admin.modules.plugins.description', phase: 'P42', icon: Icons.extension_outlined),
    AdminModule(slug: 'localization', titleKey: 'admin.modules.localization.title', descriptionKey: 'admin.modules.localization.description', phase: 'P43', icon: Icons.translate_outlined),
    AdminModule(slug: 'system-notifications', titleKey: 'admin.modules.systemNotifications.title', descriptionKey: 'admin.modules.systemNotifications.description', phase: 'P43', icon: Icons.notifications_active_outlined),
    AdminModule(slug: 'audit', permissionSlug: 'security', titleKey: 'p40.audit.title', descriptionKey: 'p40.audit.subtitle', phase: 'P40', icon: Icons.manage_search_outlined),
    AdminModule(slug: 'security', titleKey: 'admin.modules.security.title', descriptionKey: 'admin.modules.security.description', phase: 'P40', icon: Icons.security_outlined),
    AdminModule(slug: 'system', titleKey: 'admin.modules.system.title', descriptionKey: 'admin.modules.system.description', phase: 'P40', icon: Icons.settings_suggest_outlined),
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