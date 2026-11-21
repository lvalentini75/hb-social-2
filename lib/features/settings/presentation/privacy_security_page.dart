import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/safety/domain/safety_user.dart';
import 'package:hb_social/features/safety/domain/user_strike.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:hb_social/features/settings/data/settings_repository.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/features/legal/presentation/legal_consents_section.dart';

class PrivacySecurityPage extends ConsumerWidget {
  const PrivacySecurityPage({super.key});

  Future<void> _setShowSensitive(BuildContext context, WidgetRef ref, bool value) async {
    final previous = ref.read(userSettingsProvider).showSensitive;
    ref.read(userSettingsProvider.notifier).setShowSensitive(value);
    try {
      await ref.read(userSettingsRepositoryProvider).updateMine(showSensitive: value);
      ref.invalidate(privateUserSettingsProvider);
    } on AppException catch (error) {
      ref.read(userSettingsProvider.notifier).setShowSensitive(previous);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _setMessagePolicy(BuildContext context, WidgetRef ref, String value) async {
    try {
      await ref.read(userSettingsRepositoryProvider).updateMine(messagePolicy: value);
      ref.invalidate(privateUserSettingsProvider);
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, SafetyUser user, {required bool blocked}) async {
    try {
      final repository = ref.read(userSettingsRepositoryProvider);
      if (blocked) {
        await repository.unblockUser(user.id);
        ref.read(locallyBlockedUserIdsProvider.notifier).state = {...ref.read(locallyBlockedUserIdsProvider)}..remove(user.id);
        ref.invalidate(blockedUsersProvider);
        ref.invalidate(peopleSuggestionsProvider); ref.invalidate(connectionsProvider); ref.invalidate(storyTrayProvider);
      } else {
        await repository.unmuteUser(user.id);
        ref.invalidate(mutedUsersProvider);
      }
      ref.invalidate(feedPostsProvider); ref.invalidate(followingFeedProvider); ref.invalidate(nearbyFeedProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((blocked ? 'safety.user_unblocked' : 'safety.user_unmuted').tr())));
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageColumns(center: CustomScrollView(slivers: [
    SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('safety.privacy_title'.tr(), style: context.textStyles.headlineSmall))]),
      const SizedBox(height: AppSpacing.lg),
      SettingsSafetySection(
        titleKey: 'sensitive.settings_title',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('sensitive.settings_toggle'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))), Switch(value: ref.watch(userSettingsProvider.select((settings) => settings.showSensitive)), onChanged: (value) => _setShowSensitive(context, ref, value), activeColor: LightModeColors.lightPrimary)]),
          Text('sensitive.settings_help'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      MessagePrivacySection(value: ref.watch(privateUserSettingsProvider), onChanged: (value) => _setMessagePolicy(context, ref, value)),
      const SizedBox(height: AppSpacing.md),
      MyDataSection(exports: ref.watch(myDataExportsProvider), onRequest: () => _requestExport(context, ref), onDownload: (id) => _downloadExport(context, ref, id)),
      const SizedBox(height: AppSpacing.md),
      AccountDeletionSection(status: ref.watch(myAccountDeletionProvider), isAdmin: ref.watch(adminAccessProvider).value != null, onRequest: () => _requestDeletion(context, ref), onCancel: () => _cancelDeletion(context, ref)),
      const SizedBox(height: AppSpacing.md),
      const LegalConsentsSection(),
      const SizedBox(height: AppSpacing.md),
      SettingsSafetySection(titleKey: 'ads.delivery.preferences', child: Row(children: [const Icon(Icons.campaign_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('ads.delivery.preferences_help'.tr())), HBButton.ghost(label: 'common.open'.tr(), onPressed: () => context.push(AppRoutes.adsSettings))])),
      const SizedBox(height: AppSpacing.md),
      SettingsSafetySection(titleKey: 'map.privacy_title', child: Row(children: [const Icon(Icons.map_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('map.privacy_message'.tr())), HBButton.ghost(label: 'map.open_map'.tr(), onPressed: () => context.push(AppRoutes.map))])),
      const SizedBox(height: AppSpacing.md),
      SettingsSafetySection(titleKey: 'dogs.privacy_title', child: Row(children: [const Icon(Icons.pets_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('dogs.privacy_message'.tr())), HBButton.ghost(label: 'dogs.open'.tr(), onPressed: () => context.push(AppRoutes.dogs))])),
      const SizedBox(height: AppSpacing.md),
      SettingsSafetySection(titleKey: 'sightings.privacy.title', child: Row(children: [const Icon(Icons.visibility_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('sightings.privacy.message'.tr())), HBButton.ghost(label: 'sightings.privacy.open'.tr(), onPressed: () => context.push(AppRoutes.sightings))])),
      const SizedBox(height: AppSpacing.md),
      AccountStatusSection(value: ref.watch(myStrikesProvider), onRetry: () => ref.invalidate(myStrikesProvider)),
      const SizedBox(height: AppSpacing.md),
      SafetyUsersSection(
        titleKey: 'safety.blocked_title', value: ref.watch(blockedUsersProvider), emptyTitleKey: 'safety.blocked_empty_title', emptyMessageKey: 'safety.blocked_empty_message', actionKey: 'safety.unblock',
        timeKey: 'safety.action_time', onAction: (user) => _remove(context, ref, user, blocked: true), onRetry: () => ref.invalidate(blockedUsersProvider),
      ),
      const SizedBox(height: AppSpacing.md),
      SafetyUsersSection(
        titleKey: 'safety.muted_title', value: ref.watch(mutedUsersProvider), emptyTitleKey: 'safety.muted_empty_title', emptyMessageKey: 'safety.muted_empty_message', actionKey: 'safety.unmute',
        timeKey: 'safety.action_time', onAction: (user) => _remove(context, ref, user, blocked: false), onRetry: () => ref.invalidate(mutedUsersProvider),
      ),
    ])),
  ]));

  Future<void> _requestExport(BuildContext context, WidgetRef ref) async { try { await ref.read(userSettingsRepositoryProvider).requestDataExport(); ref.invalidate(myDataExportsProvider); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('p41.privacy.export_started'.tr()))); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  Future<void> _downloadExport(BuildContext context, WidgetRef ref, String id) async { try { final url = await ref.read(userSettingsRepositoryProvider).dataExportUrl(id); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async { try { await ref.read(userSettingsRepositoryProvider).requestAccountDeletion(); ref.invalidate(myAccountDeletionProvider); await ref.read(pushNotificationServiceProvider).unregisterCurrentDevice(); await ref.read(authRepositoryProvider).signOut(); if (context.mounted) context.go(AppRoutes.login); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  Future<void> _cancelDeletion(BuildContext context, WidgetRef ref) async { try { await ref.read(userSettingsRepositoryProvider).cancelAccountDeletion(); ref.invalidate(myAccountDeletionProvider); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('p41.privacy.deletion_cancelled'.tr()))); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
}

class MyDataSection extends StatelessWidget {
  final AsyncValue<List<DataExportRecord>> exports;
  final VoidCallback onRequest;
  final ValueChanged<String> onDownload;
  const MyDataSection({super.key, required this.exports, required this.onRequest, required this.onDownload});
  @override Widget build(BuildContext context) => SettingsSafetySection(titleKey: 'p41.privacy.data_title', child: exports.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('p41.privacy.export_error'.tr()), data: (items) { final item = items.isEmpty ? null : items.first; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('p41.privacy.data_info'.tr()), if (item != null) ...[const SizedBox(height: AppSpacing.sm), DataExportStatusRow(item: item, onDownload: onDownload)], const SizedBox(height: AppSpacing.md), HBButton.primary(label: item?.status == 'failed' ? 'p41.privacy.retry_export'.tr() : 'p41.privacy.download_data'.tr(), icon: Icons.archive_outlined, onPressed: const {'queued','processing'}.contains(item?.status) ? null : onRequest)]); }));
}

class DataExportStatusRow extends StatelessWidget {
  final DataExportRecord item;
  final ValueChanged<String> onDownload;
  const DataExportStatusRow({super.key, required this.item, required this.onDownload});
  @override Widget build(BuildContext context) {
    if (const {'queued','processing'}.contains(item.status)) return Row(children: [const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('p41.privacy.preparing'.tr()))]);
    if (item.status == 'ready') { final size = item.fileSize == null ? '' : '${(item.fileSize! / 1048576).toStringAsFixed(1)} MB'; final date = item.expiresAt == null ? '' : DateFormat.yMd(context.locale.toString()).format(item.expiresAt!.toLocal()); return Row(children: [Expanded(child: Text('p41.privacy.ready'.tr(namedArgs: {'size': size, 'date': date}))), HBButton.soft(label: 'p41.privacy.download'.tr(), onPressed: () => onDownload(item.id))]); }
    return Text(item.status == 'expired' ? 'p41.privacy.expired'.tr() : 'p41.privacy.failed'.tr());
  }
}

class AccountDeletionSection extends StatelessWidget {
  final AsyncValue<AccountDeletionStatus> status;
  final bool isAdmin;
  final VoidCallback onRequest;
  final VoidCallback onCancel;
  const AccountDeletionSection({super.key, required this.status, required this.isAdmin, required this.onRequest, required this.onCancel});
  @override Widget build(BuildContext context) => SettingsSafetySection(titleKey: 'p41.privacy.delete_title', child: status.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('p41.privacy.deletion_error'.tr()), data: (value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isAdmin ? 'p41.privacy.admin_delete_disabled'.tr() : 'p41.privacy.delete_info'.tr(namedArgs: {'days': '14'}), style: context.textStyles.bodyMedium?.copyWith(color: LightModeColors.lightError)), const SizedBox(height: AppSpacing.md), if (value.pending) ...[Text('p41.privacy.deletion_scheduled'.tr(namedArgs: {'date': value.eraseAfter == null ? '' : DateFormat.yMd(context.locale.toString()).format(value.eraseAfter!.toLocal())})), HBButton.soft(label: 'p41.privacy.cancel_deletion'.tr(), onPressed: onCancel)] else HBButton.soft(label: 'p41.privacy.delete_action'.tr(), icon: Icons.delete_forever_outlined, onPressed: isAdmin ? null : onRequest)])));
}

class MessagePrivacySection extends StatelessWidget {
  final AsyncValue<UserSettingsRecord?> value;
  final ValueChanged<String> onChanged;
  const MessagePrivacySection({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SettingsSafetySection(
    titleKey: 'chat.privacy.title',
    child: value.when(
      loading: () => const HBListSkeleton(count: 1),
      error: (_, __) => Text('chat.privacy.error'.tr()),
      data: (settings) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('chat.privacy.question'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        RadioListTile<String>(contentPadding: EdgeInsets.zero, title: Text('chat.privacy.everyone'.tr()), value: 'everyone', groupValue: settings?.messagePolicy ?? 'everyone', onChanged: (item) { if (item != null) onChanged(item); }),
        RadioListTile<String>(contentPadding: EdgeInsets.zero, title: Text('chat.privacy.friends'.tr()), value: 'friends', groupValue: settings?.messagePolicy ?? 'everyone', onChanged: (item) { if (item != null) onChanged(item); }),
        Text('chat.privacy.note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ]),
    ),
  );
}

/// Consistent titled card for privacy and account-safety controls.
class SettingsSafetySection extends StatelessWidget {
  final String titleKey;
  final Widget child;

  const SettingsSafetySection({super.key, required this.titleKey, required this.child});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm), child: Text(titleKey.tr().toUpperCase(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))),
    HBCard(child: child),
  ]);
}

class AccountStatusSection extends StatelessWidget {
  final AsyncValue<List<UserStrike>> value;
  final VoidCallback onRetry;

  const AccountStatusSection({super.key, required this.value, required this.onRetry});

  @override
  Widget build(BuildContext context) => SettingsSafetySection(
    titleKey: 'strikes.settings_title',
    child: value.when(
      loading: () => const HBListSkeleton(count: 2, showTrailing: false),
      error: (_, __) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'strikes.error_title'.tr(), message: 'strikes.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)),
      data: (strikes) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (strikes.isEmpty) const AccountClearRow() else for (var index = 0; index < strikes.length; index++) ...[AccountStrikeRow(strike: strikes[index]), if (index != strikes.length - 1) const Divider(height: 1, color: LightModeColors.lightDivider)],
        const SizedBox(height: AppSpacing.sm),
        Text('strikes.policy'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ]),
    ),
  );
}

class AccountStrikeRow extends StatelessWidget {
  final UserStrike strike;

  const AccountStrikeRow({super.key, required this.strike});

  @override
  Widget build(BuildContext context) {
    final expiry = strike.expiresAt == null ? null : DateFormat.yMMMd(context.locale.toString()).format(strike.expiresAt!.toLocal());
    return Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.warning_amber_rounded, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('safety.reasons.${strike.reason}'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), Text(relativeTime(context, strike.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (expiry != null) Text('strikes.expires'.tr(namedArgs: {'date': expiry}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])),
    ]));
  }
}

class AccountClearRow extends StatelessWidget {
  const AccountClearRow({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [const Icon(Icons.check_circle_rounded, color: LightModeColors.lightSuccess), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('strikes.none'.tr()))]);
}

/// Settings card containing either blocked or muted users.
class SafetyUsersSection extends StatelessWidget {
  final String titleKey;
  final AsyncValue<List<SafetyUser>> value;
  final String emptyTitleKey;
  final String emptyMessageKey;
  final String actionKey;
  final String timeKey;
  final ValueChanged<SafetyUser> onAction;
  final VoidCallback onRetry;

  const SafetyUsersSection({super.key, required this.titleKey, required this.value, required this.emptyTitleKey, required this.emptyMessageKey, required this.actionKey, required this.timeKey, required this.onAction, required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm), child: Text(titleKey.tr().toUpperCase(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))),
    HBCard(child: value.when(
      loading: () => const HBListSkeleton(count: 2),
      error: (_, __) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'safety.list_error_title'.tr(), message: 'safety.list_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)),
      data: (users) => users.isEmpty
          ? HBEmptyState(icon: Icons.shield_outlined, title: emptyTitleKey.tr(), message: emptyMessageKey.tr())
          : Column(children: [for (var index = 0; index < users.length; index++) ...[
              SafetyUserRow(user: users[index], actionKey: actionKey, timeKey: timeKey, onAction: () => onAction(users[index])),
              if (index != users.length - 1) const Divider(height: 1, color: LightModeColors.lightDivider),
            ]]),
    )),
  ]);
}

/// Compact identity row used by both privacy lists.
class SafetyUserRow extends StatelessWidget {
  final SafetyUser user;
  final String actionKey;
  final String timeKey;
  final VoidCallback onAction;

  const SafetyUserRow({super.key, required this.user, required this.actionKey, required this.timeKey, required this.onAction});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [
    HBAvatar(name: user.displayName, imageUrl: user.avatarUrl, size: 40),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      Text('@${user.username} · ${timeKey.tr(namedArgs: {'time': relativeTime(context, user.actionAt)})}', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
    ])),
    HBButton.soft(label: actionKey.tr(), onPressed: onAction, size: HBButtonSize.sm),
  ]));
}