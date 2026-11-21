import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_media_grid.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_video.dart';

class MediaViewer extends StatefulWidget {
  final MediaViewerArgs args;

  const MediaViewer({super.key, required this.args});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _controller = PageController(initialPage: widget.args.initialIndex);
  late int _index = widget.args.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: GestureDetector(
        onVerticalDragEnd: (details) { if ((details.primaryVelocity ?? 0) > 500) context.pop(); },
        child: Stack(children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.args.media.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final media = widget.args.media[index];
              if (media.kind == 'video') return Center(child: PostVideo(media: media));
              return InteractiveViewer(minScale: 1, maxScale: 4, child: Center(child: Image.network(media.url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text('feed.media_unavailable'.tr(), style: const TextStyle(color: Colors.white))))));
            },
          ),
          Positioned(top: 8, left: 0, right: 0, child: Center(child: Text('${_index + 1} / ${widget.args.media.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          Positioned(top: 0, right: 8, child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: Colors.white))),
        ]),
      ),
    ),
  );
}