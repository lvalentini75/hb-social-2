import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/notifications/domain/notification_preferences.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);
    return PageColumns(
      center: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          sliver: SliverList.list(children: [
            Text('notification_preferences.title'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('notification_preferences.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            preferences.when(
              loading: () => const HBListSkeleton(showTrailing: false),
              error: (error, stackTrace) => HBCard(child: HBEmptyState(icon: Icons.notifications_off_outlined, title: 'notification_preferences.error_title'.tr(), message: 'notification_preferences.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(notificationPreferencesProvider)))),
              data: (value) => NotificationPreferencesCard(preferences: value),
            ),
          ]),
        ),
      ]),
    );
  }
}

class NotificationPreferencesCard extends ConsumerWidget {
  final NotificationPreferences preferences;

  const NotificationPreferencesCard({super.key, required this.preferences});

  Future<void> _update(BuildContext context, WidgetRef ref, String kind, NotificationChannelPreference value) async {
    try {
      await ref.read(notificationPreferencesProvider.notifier).updatePreference(kind, value);
    } catch (error) {
      if (!context.mounted) return;
      final key = error is AppException ? error.messageKey : 'notification_preferences.save_error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => HBCard(
    child: Column(children: [
      HBTile(child: Row(children: [const Icon(Icons.shield_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('verification.notifications.service_note'.tr()))])),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [Expanded(child: Text('notification_preferences.type'.tr(), style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w700))), SizedBox(width: 72, child: Text('notification_preferences.app'.tr(), textAlign: TextAlign.center, style: context.textStyles.labelSmall)), SizedBox(width: 72, child: Text('notification_preferences.push'.tr(), textAlign: TextAlign.center, style: context.textStyles.labelSmall))]),
      ),
      const Divider(height: 1),
      for (var index = 0; index < NotificationPreferences.kinds.length; index++) ...[
        if (NotificationPreferences.kinds[index] == NotificationPreferences.messageKinds.first) NotificationPreferenceSectionLabel(label: 'nav.messages'.tr()),
        if (NotificationPreferences.kinds[index] == NotificationPreferences.sightingKinds.first) NotificationPreferenceSectionLabel(label: 'sighting_alerts.title'.tr()),
        if (NotificationPreferences.kinds[index] == NotificationPreferences.orderKinds.first) NotificationPreferenceSectionLabel(label: 'payments.notification_group'.tr()),
        if (NotificationPreferences.kinds[index] == NotificationPreferences.adsKinds.first) NotificationPreferenceSectionLabel(label: 'billing.notification_group'.tr()),
        if (NotificationPreferences.kinds[index] == NotificationPreferences.forumKinds.first) NotificationPreferenceSectionLabel(label: 'notif_settings.forum'.tr()),
        if (NotificationPreferences.kinds[index] == NotificationPreferences.eventKinds.first) NotificationPreferenceSectionLabel(label: 'notif_settings.events'.tr()),
        if (NotificationPreferences.kinds[index] == NotificationPreferences.managedKinds.first) NotificationPreferenceSectionLabel(label: 'notif_settings.managed_communities'.tr()),
        NotificationPreferenceRow(
          kind: NotificationPreferences.kinds[index],
          value: preferences.forKind(NotificationPreferences.kinds[index]),
          onChanged: (value) => _update(context, ref, NotificationPreferences.kinds[index], value),
        ),
        if (index < NotificationPreferences.kinds.length - 1) const Divider(height: 1),
      ],
    ]),
  );
}

class NotificationPreferenceSectionLabel extends StatelessWidget {
  final String label;
  const NotificationPreferenceSectionLabel({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, color: LightModeColors.lightBackgroundSoft, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm), child: Text(label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w700)));
}

class NotificationPreferenceRow extends StatelessWidget {
  final String kind;
  final NotificationChannelPreference value;
  final ValueChanged<NotificationChannelPreference> onChanged;

  const NotificationPreferenceRow({super.key, required this.kind, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    child: Row(children: [
      Expanded(child: Text((NotificationPreferences.sightingKinds.contains(kind) ? 'sighting_alerts.title' : NotificationPreferences.orderKinds.contains(kind) ? 'payments.notification_group' : NotificationPreferences.adsKinds.contains(kind) ? 'ads_schema.notification.$kind' : NotificationPreferences.messageKinds.contains(kind) ? 'chat.new' : NotificationPreferences.forumKinds.contains(kind) || NotificationPreferences.eventKinds.contains(kind) || NotificationPreferences.managedKinds.contains(kind) ? 'notif_settings.kind_$kind' : 'notification_preferences.kind_$kind').tr(namedArgs: {'reason': ''}), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      SizedBox(width: 72, child: Switch(value: value.app, onChanged: (enabled) => onChanged(value.copyWith(app: enabled)), activeColor: LightModeColors.lightPrimary)),
      SizedBox(width: 72, child: Switch(value: value.push, onChanged: (enabled) => onChanged(value.copyWith(push: enabled)), activeColor: LightModeColors.lightPrimary)),
    ]),
  );
}