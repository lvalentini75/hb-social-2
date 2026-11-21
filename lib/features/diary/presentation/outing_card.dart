import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/weather/presentation/weather_widgets.dart';

class OutingCard extends StatelessWidget {
  final Outing outing;
  final String? coverUrl;
  const OutingCard({super.key, required this.outing, this.coverUrl});

  IconData get visibilityIcon => switch (outing.visibility) { OutingVisibility.private => Icons.lock_outline_rounded, OutingVisibility.followers => Icons.people_outline_rounded, OutingVisibility.public => Icons.public_rounded };

  @override
  Widget build(BuildContext context) {
    final started = outing.startedAt.toLocal();
    final title = outing.title?.isNotEmpty == true ? outing.title! : outing.zoneName?.isNotEmpty == true ? outing.zoneName! : 'diary.default_outing'.tr();
    final species = outing.species.map((item) => item.harvestCount > 0 ? '${item.name} ${item.harvestCount}' : '${item.name} ${'diary.seen_compact'.tr(namedArgs: {'n': item.seenCount.toString()})}').join(' · ');
    return GestureDetector(onTap: () => context.push(AppRoutes.diaryDetailPath(outing.id)), child: HBCard.media(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(aspectRatio: 16 / 7, child: coverUrl == null ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.landscape_outlined, size: 40, color: LightModeColors.lightTextTertiary)) : Image.network(coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.landscape_outlined)))),
      Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('EEEE d MMMM · HH:mm', context.locale.languageCode).format(started), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBChip(label: outing.method.labelKey.tr(), selected: false), HBChip(label: outing.visibility.labelKey.tr(), selected: false, icon: visibilityIcon)]),
        if (species.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(species, maxLines: 2, overflow: TextOverflow.ellipsis)],
        const SizedBox(height: AppSpacing.sm), Row(children: [if (outing.dogs.isNotEmpty) SizedBox(width: 24 + (outing.dogs.length.clamp(1, 4) - 1) * 18, height: 28, child: Stack(children: [for (var index = 0; index < outing.dogs.take(4).length; index++) Positioned(left: index * 18, child: GestureDetector(onTap: () => context.push(AppRoutes.dogDetailPath(outing.dogs[index].id)), child: HBAvatar(name: outing.dogs[index].name, imageUrl: outing.dogs[index].avatarUrl, size: 28)))])), if (outing.dogs.isNotEmpty) const SizedBox(width: AppSpacing.sm), if (outing.weather != null) ...[WeatherConditionIcon(code: outing.weather!.weatherCode ?? 0, isDay: outing.weather!.isDay, size: 20), const SizedBox(width: 4), Text('${outing.weather!.temperature?.round()}° · ${outing.weather!.windSpeed?.round()} km/h', style: context.textStyles.bodySmall)], const Spacer(), Text(_duration(context), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]),
      ])),
    ])));
  }

  String _duration(BuildContext context) {
    final minutes = outing.durationMin ?? outing.endedAt?.difference(outing.startedAt).inMinutes;
    if (minutes == null) return '';
    final hours = minutes ~/ 60; final rest = minutes % 60;
    return hours == 0 ? 'diary.duration_minutes'.tr(namedArgs: {'n': '$rest'}) : 'diary.duration_hours'.tr(namedArgs: {'h': '$hours', 'm': '$rest'});
  }
}