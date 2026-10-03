import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/messages/domain/conversation.dart';
import 'package:hb_social/features/messages/providers/conversation_providers.dart';

/// Conversation thread at `/messages/:id`. No messaging backend yet, so the
/// thread always renders an explicit "no messages yet" state instead of any
/// sample conversation. [debugPreview] (only reachable from
/// `/dev/design-system` in debug mode) renders the full layout with every
/// field null, shown as "—".
class ConversationDetailPage extends ConsumerWidget {
  final String conversationId;
  final bool debugPreview;

  const ConversationDetailPage({super.key, required this.conversationId, this.debugPreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugPreview) {
      return const _ThreadBody(conversation: null);
    }

    final conversationAsync = ref.watch(conversationByIdProvider(conversationId));
    return conversationAsync.when(
      loading: () => const PageColumns(center: Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator()))),
      error: (error, stackTrace) => PageColumns(
        center: HBCard(
          child: HBEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'messages.error_title'.tr(),
            message: 'messages.error_message'.tr(),
            action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(conversationByIdProvider(conversationId))),
          ),
        ),
      ),
      data: (conversation) {
        if (conversation == null) {
          return PageColumns(
            center: HBCard(
              child: HBEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'messages.not_found_title'.tr(), message: 'messages.not_found_message'.tr()),
            ),
          );
        }
        return _ThreadBody(conversation: conversation);
      },
    );
  }
}

class _ThreadBody extends StatelessWidget {
  final Conversation? conversation;

  const _ThreadBody({required this.conversation});

  void _showSoon(BuildContext context, String sectionKey) => showComingSoonInfo(
    context,
    icon: Icons.chat_bubble_outline_rounded,
    title: 'common.coming_soon_title'.tr(),
    message: 'common.coming_soon_message'.tr(namedArgs: {'section': sectionKey.tr()}),
  );

  @override
  Widget build(BuildContext context) {
    final name = conversation?.participantName;
    return PageColumns(
      center: HBCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  HBAvatar(name: name, size: 40, isGuest: name == null || name.isEmpty),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      (name == null || name.isEmpty) ? '—' : name,
                      style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  HBButton.icon(icon: Icons.info_outline_rounded, onPressed: () => _showSoon(context, 'messages.thread_info')),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 360,
              child: HBEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'messages.thread_empty_title'.tr(),
                message: 'messages.thread_empty_message'.tr(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: HBInput(hint: 'messages.thread_input_hint'.tr())),
                  const SizedBox(width: AppSpacing.sm),
                  HBButton.icon(icon: Icons.send_rounded, onPressed: () => _showSoon(context, 'messages.thread_send')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
