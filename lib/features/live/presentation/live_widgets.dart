import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/features/live/domain/live_models.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveVideoStage extends StatelessWidget {
  final Room? room;
  final bool local;
  final BoxFit fit;
  const LiveVideoStage({super.key, required this.room, this.local = false, this.fit = BoxFit.cover});

  @override Widget build(BuildContext context) {
    final value = room;
    if (value == null) return const ColoredBox(color: LightModeColors.night, child: Center(child: CircularProgressIndicator(color: Colors.white)));
    return ListenableBuilder(listenable: value, builder: (context, _) {
      VideoTrack? track;
      if (local) {
        final publication = value.localParticipant?.videoTrackPublications.where((item) => item.track != null).firstOrNull;
        if (publication?.track is VideoTrack) track = publication!.track as VideoTrack;
      } else {
        final publication = value.remoteParticipants.values.firstOrNull?.videoTrackPublications.where((item) => item.track != null).firstOrNull;
        if (publication?.track is VideoTrack) track = publication!.track as VideoTrack;
      }
      if (track is VideoTrack) return VideoTrackRenderer(track, fit: fit == BoxFit.cover ? VideoViewFit.cover : VideoViewFit.contain);
      return ColoredBox(color: LightModeColors.night, child: Center(child: Icon(local ? Icons.videocam_off_outlined : Icons.person_outline_rounded, color: Colors.white70, size: 64)));
    });
  }
}

class LiveStreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback onTap;
  const LiveStreamCard({super.key, required this.stream, required this.onTap});
  @override Widget build(BuildContext context) {
    final cover = storagePublicUrl(Supabase.instance.client, 'story-media', stream.coverPath);
    final scheduled = stream.status == 'scheduled';
    return SizedBox(width: 150, height: 200, child: Material(color: LightModeColors.night, borderRadius: BorderRadius.circular(AppRadius.inner), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Stack(fit: StackFit.expand, children: [
      if (cover.isNotEmpty) Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()) else Center(child: HBAvatar(name: stream.host.displayName, imageUrl: stream.host.avatarUrl, size: 72)),
      const ColoredBox(color: Color.fromRGBO(20, 28, 24, .35)),
      Positioned(left: 10, top: 10, child: DecoratedBox(decoration: BoxDecoration(color: scheduled ? LightModeColors.bosco : LightModeColors.danger, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(scheduled ? 'live.scheduled_in'.tr(namedArgs: {'time': stream.scheduledAt == null ? '' : DateFormat.Hm().format(stream.scheduledAt!.toLocal())}) : 'live.badge'.tr(namedArgs: {'count': '${stream.viewerCount}'}), style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700))))),
      Positioned(left: 10, right: 10, bottom: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(stream.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.cardTitle.copyWith(color: Colors.white)), const SizedBox(height: 4), Text(stream.host.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: Colors.white70))])),
    ]))));
  }
}