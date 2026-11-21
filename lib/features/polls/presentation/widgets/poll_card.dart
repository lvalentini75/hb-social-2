import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/polls/domain/poll.dart';
import 'package:hb_social/features/polls/providers/poll_providers.dart';

class PollCard extends ConsumerStatefulWidget {
  final Poll poll;

  const PollCard({super.key, required this.poll});

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  late Poll _poll = widget.poll;
  final Set<String> _selected = {};
  bool _submitting = false;

  bool get _showResults => _poll.myOptionIds.isNotEmpty || _poll.isClosed;

  Future<void> _vote(Set<String> ids) async {
    setState(() => _submitting = true);
    try {
      final updated = await ref.read(pollRepositoryProvider).vote(_poll, ids);
      if (mounted) setState(() { _poll = updated; _selected.clear(); });
    } on AppException catch (error) {
      if (!mounted) return;
      if (error.messageKey == 'errors.login_required') {
        context.push(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _select(String id) {
    if (_poll.isClosed || _showResults) return;
    setState(() {
      if (_poll.allowMultiple) {
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
      } else {
        _selected..clear()..add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_poll.question.isNotEmpty) Text(_poll.question, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.sm),
      for (final option in _poll.options) PollOptionRow(
        option: option,
        selected: _showResults ? _poll.myOptionIds.contains(option.id) : _selected.contains(option.id),
        showResults: _showResults,
        allowMultiple: _poll.allowMultiple,
        totalVotes: _poll.totalVotes,
        onTap: () => _select(option.id),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (!_showResults && !_poll.isClosed) HBButton.primary(label: 'polls.vote'.tr(), onPressed: _selected.isEmpty ? null : () => _vote(_selected), isLoading: _submitting, size: HBButtonSize.sm),
      if (_showResults && !_poll.isClosed) HBButton.ghost(label: 'polls.withdraw'.tr(), onPressed: () => _vote({}), isLoading: _submitting, size: HBButtonSize.sm),
      const SizedBox(height: AppSpacing.xs),
      Text(
        _poll.isClosed
            ? 'polls.closed'.tr()
            : 'polls.meta'.tr(namedArgs: {'votes': 'polls.votes'.plural(_poll.totalVotes), 'deadline': _poll.endsAt == null ? 'polls.no_end'.tr() : 'polls.ends'.tr(namedArgs: {'time': relativeTime(context, _poll.endsAt!)})}),
        style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant),
      ),
    ]),
  );
}

class PollOptionRow extends StatelessWidget {
  final PollOption option;
  final bool selected;
  final bool showResults;
  final bool allowMultiple;
  final int totalVotes;
  final VoidCallback onTap;

  const PollOptionRow({super.key, required this.option, required this.selected, required this.showResults, required this.allowMultiple, required this.totalVotes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percentage = totalVotes == 0 ? 0 : (option.voteCount * 100 / totalVotes).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: selected ? LightModeColors.lightPrimarySoft : LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Column(children: [
            Row(children: [
              Icon(allowMultiple ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded) : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded), size: 20, color: selected ? LightModeColors.lightPrimary : LightModeColors.lightTextTertiary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(option.label)),
              if (showResults) Text('$percentage%', style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            if (showResults) ...[
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: LinearProgressIndicator(value: percentage / 100, minHeight: 5, backgroundColor: LightModeColors.lightDivider, color: selected ? LightModeColors.lightPrimary : LightModeColors.lightTextTertiary)),
            ],
          ]),
        ),
      ),
    );
  }
}