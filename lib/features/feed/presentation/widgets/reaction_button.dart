import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/feed/domain/reaction.dart';

class ReactionButton extends StatefulWidget {
  final String postId;
  final String? initialReaction;
  final int initialCount;
  final Future<ReactionToggleResult> Function(ReactionType type) onToggle;
  final ValueChanged<ReactionToggleResult>? onChanged;

  /// PD4 feed row: a borderless icon + counter instead of the soft pill.
  final bool compact;

  const ReactionButton({super.key, required this.postId, this.initialReaction, required this.initialCount, required this.onToggle, this.onChanged, this.compact = false});

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  static _ReactionButtonState? _activePickerOwner;

  final LayerLink _layerLink = LayerLink();
  Timer? _openTimer;
  Timer? _closeTimer;
  OverlayEntry? _pickerEntry;
  ScrollPosition? _scrollPosition;
  late String? _reaction = widget.initialReaction;
  late int _count = widget.initialCount;
  bool _busy = false;
  bool _popping = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (nextPosition == _scrollPosition) return;
    _scrollPosition?.removeListener(_hidePicker);
    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_hidePicker);
  }

  @override
  void didUpdateWidget(covariant ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialReaction != widget.initialReaction) _reaction = widget.initialReaction;
    if (oldWidget.initialCount != widget.initialCount) _count = widget.initialCount;
  }

  Future<void> _toggle(ReactionType type) async {
    if (_busy) return;
    final previousReaction = _reaction;
    final previousCount = _count;
    final removing = previousReaction == type.value;
    setState(() {
      _busy = true;
      _popping = true;
      _reaction = removing ? null : type.value;
      _count = (previousCount + (previousReaction == null ? 1 : removing ? -1 : 0)).clamp(0, 1 << 30);
    });
    Future<void>.delayed(Duration(milliseconds: AppMotion.of(context).medium.inMilliseconds ~/ 2), () { if (mounted) setState(() => _popping = false); });
    try {
      final result = await widget.onToggle(type);
      if (mounted) setState(() { _reaction = result.myReaction; _count = result.reactionCount; });
      widget.onChanged?.call(result);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() { _reaction = previousReaction; _count = previousCount; });
      if (error.messageKey == 'errors.login_required') {
        context.push(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scheduleOpen() {
    _closeTimer?.cancel();
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 300), _showPicker);
  }

  void _scheduleClose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 200), _hidePicker);
  }

  void _showPicker() {
    _openTimer?.cancel();
    if (_pickerEntry != null) return;
    _activePickerOwner?._hidePicker();
    _activePickerOwner = this;

    final screenSize = MediaQuery.sizeOf(context);
    final targetBox = context.findRenderObject() as RenderBox?;
    final targetLeft = targetBox?.localToGlobal(Offset.zero).dx ?? 0;
    final pickerWidth = math.min(ReactionPicker.preferredWidth, screenSize.width - 24);
    final rightOverflow = math.max(0.0, targetLeft + pickerWidth - (screenSize.width - 12));

    _pickerEntry = OverlayEntry(builder: (overlayContext) => Stack(children: [
      Positioned.fill(child: Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => _hidePicker(), onPointerSignal: (_) => _hidePicker())),
      CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        offset: Offset(-rightOverflow, -8),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: pickerWidth,
            child: ReactionPicker(
              onEnter: () => _closeTimer?.cancel(),
              onExit: _scheduleClose,
              onSelected: (type) {
                _hidePicker();
                _toggle(type);
              },
            ),
          ),
        ),
      ),
    ]));
    Overlay.of(context, rootOverlay: true).insert(_pickerEntry!);
  }

  void _hidePicker() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _pickerEntry?.remove();
    _pickerEntry = null;
    if (_activePickerOwner == this) _activePickerOwner = null;
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_hidePicker);
    _hidePicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ReactionTypeUi.parse(_reaction);
    if (widget.compact) {
      final active = selected != null;
      return CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          onEnter: (_) => _scheduleOpen(),
          onExit: (_) => _scheduleClose(),
          child: InkWell(
            onTap: () => _toggle(selected ?? ReactionType.like),
            onLongPress: _showPicker,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedScale(scale: _popping ? 1.25 : 1, duration: AppMotion.of(context).medium, curve: AppMotion.enter, child: Icon(active ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 22, color: active ? LightModeColors.danger : LightModeColors.textSecondary)),
                if (_count > 0) ...[const SizedBox(width: AppSpacing.xs), Text('$_count', style: AppText.ui.withColor(LightModeColors.textSecondary))],
              ]),
            ),
          ),
        ),
      );
    }
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _scheduleOpen(),
        onExit: (_) => _scheduleClose(),
        child: InkWell(
          onTap: () => _toggle(selected ?? ReactionType.like),
          onLongPress: _showPicker,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedScale(scale: _popping ? 1.25 : 1, duration: AppMotion.of(context).medium, curve: AppMotion.enter, child: Icon(selected?.icon ?? Icons.thumb_up_alt_outlined, size: 18, color: LightModeColors.lightPrimary)),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text((selected?.labelKey ?? 'feed.like').tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightPrimary))),
            ]),
          ),
        ),
      ),
    );
  }
}

class ReactionPicker extends StatefulWidget {
  static const double preferredWidth = 280;

  final ValueChanged<ReactionType> onSelected;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const ReactionPicker({super.key, required this.onSelected, required this.onEnter, required this.onExit});

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150))..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  ReactionType? _hovered;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => widget.onEnter(),
    onExit: (_) => widget.onExit(),
    child: FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomLeft,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(color: LightModeColors.lightSurface, borderRadius: BorderRadius.circular(AppRadius.pill), boxShadow: AppShadows.level2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final type in ReactionType.values)
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = type),
                onExit: (_) => setState(() => _hovered = null),
                child: AnimatedScale(
                  scale: _hovered == type ? 1.2 : 1,
                  duration: const Duration(milliseconds: 120),
                  child: IconButton(
                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    padding: EdgeInsets.zero,
                    tooltip: type.labelKey.tr(),
                    onPressed: () => widget.onSelected(type),
                    icon: Icon(type.icon, size: 32, color: type.color),
                  ),
                ),
              ),
          ]),
        ),
      ),
    ),
  );
}