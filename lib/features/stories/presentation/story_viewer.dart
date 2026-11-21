import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/stories/domain/story.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/stories/presentation/highlight_editor.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:video_player/video_player.dart';

class StoryViewerPage extends ConsumerStatefulWidget {
  final String? username;
  final StoryHighlight? highlight;
  final UserProfile? highlightOwner;

  const StoryViewerPage({super.key, required String this.username}) : highlight = null, highlightOwner = null;
  const StoryViewerPage.highlight({super.key, required StoryHighlight this.highlight, required UserProfile owner}) : username = null, highlightOwner = owner;

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage> {
  final _focusNode = FocusNode();
  final Set<String> _locallyViewed = {};
  final Set<String> _deletedIds = {};
  Timer? _timer;
  int _index = 0;
  double _progress = 0;
  Duration _duration = const Duration(seconds: 5);
  DateTime? _startedAt;
  bool _paused = false;
  String? _configuredAuthorId;
  String? _markedStoryId;
  bool _highlightConfigured = false;

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _start(Duration duration) {
    _timer?.cancel();
    _duration = duration;
    _progress = 0;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _paused || _startedAt == null) return;
      final value = DateTime.now().difference(_startedAt!).inMilliseconds / _duration.inMilliseconds;
      if (value >= 1) {
        _timer?.cancel();
        _next();
      } else {
        setState(() => _progress = value);
      }
    });
  }

  void _setPaused(bool paused) {
    if (_paused == paused) return;
    setState(() {
      _paused = paused;
      if (!paused) _startedAt = DateTime.now().subtract(Duration(milliseconds: (_duration.inMilliseconds * _progress).round()));
    });
  }

  void _close() {
    if (context.canPop()) context.pop(); else context.go(AppRoutes.home);
  }

  List<Story> _visibleStories(StoryViewerData data) => data.stories.where((story) => !_deletedIds.contains(story.id)).toList();

  void _configure(StoryTrayItem author, StoryViewerData data) {
    if (_configuredAuthorId == author.authorId) return;
    _configuredAuthorId = author.authorId;
    final stories = _visibleStories(data);
    final index = stories.indexWhere((story) => !data.viewedStoryIds.contains(story.id) && !_locallyViewed.contains(story.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || stories.isEmpty) return;
      setState(() => _index = index < 0 ? 0 : index);
      _activate(stories[_index]);
    });
  }

  void _activate(Story story) {
    _markedStoryId = null;
    _start(story.kind == 'image' ? const Duration(seconds: 5) : const Duration(seconds: 15));
    WidgetsBinding.instance.addPostFrameCallback((_) => _markViewed(story));
  }

  void _activateHighlight(Story story) {
    _markedStoryId = null;
    _start(story.kind == 'image' ? const Duration(seconds: 5) : const Duration(seconds: 15));
  }

  Future<void> _markViewed(Story story) async {
    if (_markedStoryId == story.id) return;
    _markedStoryId = story.id;
    final own = story.authorId == ref.read(storyRepositoryProvider).currentUserId;
    if (own) return;
    _locallyViewed.add(story.id);
    await ref.read(storyRepositoryProvider).markViewed(story.id);
    ref.invalidate(storyTrayProvider);
  }

  void _previous() {
    final author = _currentAuthor;
    final data = author == null ? null : ref.read(authorStoriesProvider(author.authorId)).value;
    final stories = data == null ? const <Story>[] : _visibleStories(data);
    if (_index <= 0 || stories.isEmpty) return;
    setState(() => _index--);
    _activate(stories[_index]);
  }

  StoryTrayItem? get _currentAuthor {
    final items = ref.read(storyTrayProvider).value;
    if (items == null) return null;
    for (final item in items) {
      if (item.username == widget.username) return item;
    }
    return null;
  }

  void _next() {
    final author = _currentAuthor;
    final data = author == null ? null : ref.read(authorStoriesProvider(author.authorId)).value;
    final stories = data == null ? const <Story>[] : _visibleStories(data);
    if (_index + 1 < stories.length) {
      setState(() => _index++);
      _activate(stories[_index]);
      return;
    }
    final tray = ref.read(storyTrayProvider).value ?? const <StoryTrayItem>[];
    final authorIndex = tray.indexWhere((item) => item.username == widget.username);
    if (authorIndex >= 0 && authorIndex + 1 < tray.length) {
      context.go(AppRoutes.storyPath(tray[authorIndex + 1].username));
    } else {
      _close();
    }
  }

  List<Story> get _highlightStories => widget.highlight!.stories.map((story) => story.toStory(widget.highlightOwner!)).toList();

  void _configureHighlight() {
    if (_highlightConfigured || _highlightStories.isEmpty) return;
    _highlightConfigured = true;
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _activateHighlight(_highlightStories.first); });
  }

  void _highlightPrevious() {
    if (_index <= 0) return;
    setState(() => _index--);
    _activateHighlight(_highlightStories[_index]);
  }

  void _highlightNext() {
    if (_index + 1 >= _highlightStories.length) { _close(); return; }
    setState(() => _index++);
    _activateHighlight(_highlightStories[_index]);
  }

  Future<void> _renameHighlight() async {
    final controller = TextEditingController(text: widget.highlight!.title);
    final title = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text('story_highlights.rename'.tr()), content: TextField(controller: controller, maxLength: 40), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'story_highlights.save'.tr(), onPressed: () => context.pop(controller.text))]));
    controller.dispose();
    if (title == null || !mounted) return;
    try { await ref.read(storyRepositoryProvider).renameHighlight(widget.highlight!.id, title); if (mounted) _close(); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('story_highlights.error_message'.tr()))); }
  }

  Future<void> _editHighlight() async {
    if (await showHighlightEditor(context, highlight: widget.highlight) && mounted) _close();
  }

  Future<void> _deleteHighlight() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('story_highlights.delete_title'.tr()), content: Text('story_highlights.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'story_highlights.delete'.tr(), onPressed: () => context.pop(true))]));
    if (confirmed != true || !mounted) return;
    try { await ref.read(storyRepositoryProvider).deleteHighlight(widget.highlight!.id); if (mounted) _close(); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('story_highlights.error_message'.tr()))); }
  }

  Widget _buildHighlight(BuildContext context) {
    final stories = _highlightStories;
    if (stories.isEmpty) return Scaffold(backgroundColor: Colors.black, body: StoryViewerError(onClose: _close));
    _configureHighlight();
    final safeIndex = _index.clamp(0, stories.length - 1);
    final story = stories[safeIndex];
    final isOwn = widget.highlight!.ownerId == ref.watch(storyRepositoryProvider).currentUserId;
    return Scaffold(backgroundColor: Colors.black, body: KeyboardListener(focusNode: _focusNode, autofocus: true, onKeyEvent: (event) {
      if (event is! KeyDownEvent) return;
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) _highlightNext();
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _highlightPrevious();
      if (event.logicalKey == LogicalKeyboardKey.escape) _close();
    }, child: GestureDetector(onVerticalDragEnd: (details) { if ((details.primaryVelocity ?? 0) > 350) _close(); }, onLongPressStart: (_) => _setPaused(true), onLongPressEnd: (_) => _setPaused(false), child: SafeArea(child: Stack(fit: StackFit.expand, children: [
      GestureDetector(onTapUp: (details) => details.localPosition.dx < MediaQuery.sizeOf(context).width / 2 ? _highlightPrevious() : _highlightNext(), child: StoryMedia(story: story, paused: _paused, onDuration: _start, onError: () => _start(const Duration(seconds: 2)))),
      Positioned(top: AppSpacing.sm, left: AppSpacing.sm, right: AppSpacing.sm, child: StoryViewerHeader(stories: stories, index: safeIndex, progress: _progress, story: story, title: widget.highlight!.title, onClose: _close, onReport: isOwn ? null : () => _reportStory(story), onRenameHighlight: isOwn ? _renameHighlight : null, onEditHighlight: isOwn ? _editHighlight : null, onDeleteHighlight: isOwn ? _deleteHighlight : null)),
      if (story.caption?.isNotEmpty == true) Positioned(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg, child: Text(story.caption!, textAlign: TextAlign.center, style: context.textStyles.bodyLarge?.copyWith(color: Colors.white, shadows: const [Shadow(blurRadius: 8, color: Colors.black)]))),
    ])))));
  }

  Future<void> _delete(Story story) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('story_viewer.delete_title'.tr()),
      content: Text('story_viewer.delete_message'.tr()),
      actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'story_viewer.delete'.tr(), onPressed: () => context.pop(true))],
    ));
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(storyRepositoryProvider).deleteStory(story, ref.read(mediaUploadServiceProvider));
      _deletedIds.add(story.id);
      _index = (_index - 1).clamp(0, 1 << 20);
      ref.invalidate(storyTrayProvider);
      ref.invalidate(authorStoriesProvider(story.authorId));
      _next();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('story_viewer.delete_error'.tr())));
    }
  }

  Future<void> _reportStory(Story story) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    _setPaused(true);
    final reported = await showReportSheet(context, targetType: 'story', targetId: story.id);
    if (!mounted) return;
    _setPaused(false);
    if (reported) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.report_success'.tr())));
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) _next();
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _previous();
    if (event.logicalKey == LogicalKeyboardKey.space) _setPaused(!_paused);
    if (event.logicalKey == LogicalKeyboardKey.escape) _close();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.highlight != null) return _buildHighlight(context);
    final tray = ref.watch(storyTrayProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: tray.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => StoryViewerError(onClose: _close),
          data: (items) {
             final matching = items.where((item) => item.username == widget.username);
            if (matching.isEmpty) return StoryViewerError(onClose: _close);
            final author = matching.first;
            final storiesValue = ref.watch(authorStoriesProvider(author.authorId));
            return storiesValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => StoryViewerError(onClose: _close),
              data: (data) {
                _configure(author, data);
                final stories = _visibleStories(data);
                if (stories.isEmpty) return StoryViewerError(onClose: _close);
                final safeIndex = _index.clamp(0, stories.length - 1);
                final story = stories[safeIndex];
                final isOwn = story.authorId == ref.watch(storyRepositoryProvider).currentUserId;
                return GestureDetector(
                  onVerticalDragEnd: (details) { if ((details.primaryVelocity ?? 0) > 350) _close(); },
                  onLongPressStart: (_) => _setPaused(true),
                  onLongPressEnd: (_) => _setPaused(false),
                  child: SafeArea(child: Stack(fit: StackFit.expand, children: [
                    GestureDetector(onTapUp: (details) => details.localPosition.dx < MediaQuery.sizeOf(context).width / 2 ? _previous() : _next(), child: StoryMedia(story: story, paused: _paused, onDuration: (duration) => _start(duration), onError: () => _start(const Duration(seconds: 2)))),
                    Positioned(top: AppSpacing.sm, left: AppSpacing.sm, right: AppSpacing.sm, child: StoryViewerHeader(stories: stories, index: safeIndex, progress: _progress, story: story, onClose: _close, onReport: isOwn ? null : () => _reportStory(story), onDelete: isOwn ? () => _delete(story) : null, onAddToHighlight: isOwn ? () => showAddStoryToHighlight(context, ref, story) : null)),
                    if (story.caption?.isNotEmpty == true) Positioned(left: AppSpacing.lg, right: AppSpacing.lg, bottom: isOwn ? 72 : AppSpacing.lg, child: Text(story.caption!, textAlign: TextAlign.center, style: context.textStyles.bodyLarge?.copyWith(color: Colors.white, shadows: const [Shadow(blurRadius: 8, color: Colors.black)]))),
                    if (isOwn) Positioned(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md, child: Center(child: HBButton.ghost(label: 'story_viewer.seen_by'.tr(namedArgs: {'n': story.viewCount.toString()}), icon: Icons.visibility_outlined, onPressed: () => showStoryViewers(context, story.id)))),
                  ])),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class StoryViewerHeader extends StatelessWidget {
  final List<Story> stories;
  final int index;
  final double progress;
  final Story story;
  final VoidCallback onClose;
  final VoidCallback? onDelete;
  final String? title;
  final VoidCallback? onAddToHighlight;
  final VoidCallback? onRenameHighlight;
  final VoidCallback? onEditHighlight;
  final VoidCallback? onDeleteHighlight;
  final VoidCallback? onReport;

  const StoryViewerHeader({super.key, required this.stories, required this.index, required this.progress, required this.story, required this.onClose, this.onDelete, this.title, this.onAddToHighlight, this.onRenameHighlight, this.onEditHighlight, this.onDeleteHighlight, this.onReport});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [for (var item = 0; item < stories.length; item++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: LinearProgressIndicator(value: item < index ? 1 : item == index ? progress : 0, minHeight: 3, color: Colors.white, backgroundColor: Colors.white38)))]),
    const SizedBox(height: AppSpacing.sm),
    Row(children: [
      HBAvatar(name: story.author.displayName, imageUrl: story.author.avatarUrl, size: 32, ringColor: Colors.white),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(title ?? '${story.author.displayName} · ${relativeTime(context, story.createdAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelLarge?.copyWith(color: Colors.white))),
      if (onDelete != null || onAddToHighlight != null || onRenameHighlight != null || onReport != null) PopupMenuButton<String>(iconColor: Colors.white, onSelected: (value) { if (value == 'delete') onDelete?.call(); if (value == 'add') onAddToHighlight?.call(); if (value == 'rename') onRenameHighlight?.call(); if (value == 'edit') onEditHighlight?.call(); if (value == 'delete_highlight') onDeleteHighlight?.call(); if (value == 'report') onReport?.call(); }, itemBuilder: (_) => [
        if (onReport != null) PopupMenuItem(value: 'report', child: Text('safety.report_story'.tr())),
        if (onAddToHighlight != null) PopupMenuItem(value: 'add', child: Text('story_highlights.add_to'.tr())),
        if (onDelete != null) PopupMenuItem(value: 'delete', child: Text('story_viewer.delete'.tr())),
        if (onRenameHighlight != null) PopupMenuItem(value: 'rename', child: Text('story_highlights.rename'.tr())),
        if (onEditHighlight != null) PopupMenuItem(value: 'edit', child: Text('story_highlights.edit_stories'.tr())),
        if (onDeleteHighlight != null) PopupMenuItem(value: 'delete_highlight', child: Text('story_highlights.delete'.tr())),
      ]),
      IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: Colors.white)),
    ]),
  ]);
}

class StoryMedia extends StatefulWidget {
  final Story story;
  final bool paused;
  final ValueChanged<Duration> onDuration;
  final VoidCallback onError;

  const StoryMedia({super.key, required this.story, required this.paused, required this.onDuration, required this.onError});

  @override
  State<StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends State<StoryMedia> {
  VideoPlayerController? _controller;
  bool _muted = kIsWeb;
  bool _failed = false;
  bool _videoReady = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    if (widget.story.kind == 'video') _initialize();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.story.mediaUrl));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setVolume(_muted ? 0 : 1);
      controller.addListener(_onVideoFrame);
      if (!_reduceMotion) await controller.play();
      if (mounted) {
        setState(() {});
        widget.onDuration(controller.value.duration);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      widget.onError();
    }
  }

  @override void didChangeDependencies() { super.didChangeDependencies(); final value = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context); if (_reduceMotion != value) { _reduceMotion = value; if (value) _controller?.pause(); } }

  void _onVideoFrame() {
    if (!mounted || _videoReady || (_controller?.value.position ?? Duration.zero) <= Duration.zero) return;
    setState(() => _videoReady = true);
  }

  @override
  void didUpdateWidget(covariant StoryMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story.id != widget.story.id) {
      unawaited(_controller?.dispose());
      _controller = null;
      _failed = false;
      _videoReady = false;
      if (widget.story.kind == 'video') _initialize();
    } else if (_controller?.value.isInitialized == true) {
      widget.paused || _reduceMotion ? _controller!.pause() : _controller!.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoFrame);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const StoryUnavailable();
    if (widget.story.kind == 'image') return Image.network(widget.story.mediaUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) { WidgetsBinding.instance.addPostFrameCallback((_) => widget.onError()); return const StoryUnavailable(); });
    final controller = _controller;
    return Stack(fit: StackFit.expand, children: [
      if (widget.story.thumbnailUrl?.isNotEmpty == true) Image.network(widget.story.thumbnailUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const StoryVideoPlaceholder()) else const StoryVideoPlaceholder(),
      if (_videoReady && controller?.value.isInitialized == true) Center(child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller))),
      if (!_videoReady) const Center(child: CircularProgressIndicator(color: LightModeColors.lightPrimary)),
      if (kIsWeb && controller?.value.isInitialized == true) Positioned(right: AppSpacing.md, bottom: AppSpacing.md, child: IconButton(tooltip: 'a11y.toggle_audio'.tr(), onPressed: () { setState(() => _muted = !_muted); controller!.setVolume(_muted ? 0 : 1); }, icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white))),
    ]);
  }
}

class StoryVideoPlaceholder extends StatelessWidget {
  const StoryVideoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.videocam_outlined, color: LightModeColors.lightTextTertiary, size: 42),
    const SizedBox(height: AppSpacing.xs),
    Text('media.video'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
  ])));
}

class StoryUnavailable extends StatelessWidget {
  const StoryUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Center(child: Text('story_viewer.unavailable'.tr(), style: context.textStyles.bodyLarge?.copyWith(color: Colors.white)));
}

class StoryViewerError extends StatelessWidget {
  final VoidCallback onClose;

  const StoryViewerError({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) => Center(child: HBEmptyState(icon: Icons.broken_image_outlined, title: 'story_viewer.empty_title'.tr(), message: 'story_viewer.empty_message'.tr(), action: HBButton.secondary(label: 'common.back'.tr(), onPressed: onClose)));
}

Future<void> showStoryViewers(BuildContext context, String storyId) => showModalBottomSheet<void>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => StoryViewersSheet(storyId: storyId));

class StoryViewersSheet extends ConsumerWidget {
  final String storyId;

  const StoryViewersSheet({super.key, required this.storyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewers = ref.watch(storyViewersProvider(storyId));
    return SizedBox(height: MediaQuery.sizeOf(context).height * .6, child: Column(children: [
      Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('story_viewer.viewers_title'.tr(), style: context.textStyles.titleLarge)),
      Expanded(child: viewers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('story_viewer.viewers_error'.tr())),
        data: (items) => items.isEmpty
            ? HBEmptyState(icon: Icons.visibility_outlined, title: 'story_viewer.no_viewers_title'.tr(), message: 'story_viewer.no_viewers_message'.tr())
            : ListView.builder(itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; return ListTile(leading: HBAvatar(name: item.viewer.displayName, imageUrl: item.viewer.avatarUrl, size: 40), title: Text(item.viewer.displayName), subtitle: Text('@${item.viewer.username} · ${relativeTime(context, item.viewedAt)}')); }),
      )),
    ]));
  }
}