import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';

class AdminPersonCell extends StatelessWidget {
  final AdminPerson person;
  final double avatarSize;
  final bool showUsername;

  const AdminPersonCell({super.key, required this.person, this.avatarSize = 32, this.showUsername = true});

  @override
  Widget build(BuildContext context) => Row(children: [HBAvatar(size: avatarSize, imageUrl: person.avatarUrl, name: person.displayName), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(person.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.bold), if (showUsername) Text('@${person.username}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))]);
}

class AdminReadOnlyAction extends StatelessWidget {
  final String label;
  final bool destructive;

  const AdminReadOnlyAction({super.key, required this.label, this.destructive = false});

  @override
  Widget build(BuildContext context) => Tooltip(message: 'admin.p05b.futureAction'.tr(), child: HBButton.secondary(label: label, onPressed: null, size: HBButtonSize.sm, foregroundColor: destructive ? LightModeColors.lightError : null));
}

class AdminDetailCard extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminDetailCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: HBCard(radius: AppRadius.sm, padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm), child])));
}

class AdminDashText extends StatelessWidget {
  const AdminDashText({super.key});
  @override Widget build(BuildContext context) => Text('common.unavailable'.tr());
}