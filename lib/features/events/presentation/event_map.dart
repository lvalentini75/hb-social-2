import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:latlong2/latlong.dart';

class EventMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool editable;
  final ValueChanged<LatLng>? onChanged;
  final double height;

  const EventMap({super.key, required this.latitude, required this.longitude, this.editable = false, this.onChanged, this.height = 260});

  @override
  State<EventMap> createState() => _EventMapState();
}

class _EventMapState extends State<EventMap> {
  final _mapKey = GlobalKey();
  final _controller = MapController();

  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.latitude, widget.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: widget.height,
        child: Stack(children: [
          FlutterMap(
            key: _mapKey,
            mapController: _controller,
            options: MapOptions(initialCenter: point, initialZoom: 13, onTap: widget.editable ? (_, location) => widget.onChanged?.call(location) : null),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'),
              MarkerLayer(markers: [Marker(point: point, width: 48, height: 48, child: widget.editable ? Draggable<LatLng>(data: point, feedback: const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError), childWhenDragging: const SizedBox.shrink(), onDragEnd: (details) { final box = _mapKey.currentContext?.findRenderObject() as RenderBox?; if (box != null) widget.onChanged?.call(_controller.camera.screenOffsetToLatLng(box.globalToLocal(details.offset + const Offset(24, 44)))); }, child: const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError)) : const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError))]),
              RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})]),
            ],
          ),
          if (widget.editable) Positioned(left: AppSpacing.sm, top: AppSpacing.sm, right: AppSpacing.sm, child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightSurface.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(AppRadius.sm)), child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text('events.form.map_help'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall))))),
        ]),
      ),
    );
  }
}

class EventStatusConfirmation extends StatelessWidget {
  final String titleKey;
  final String messageKey;
  final String actionKey;
  const EventStatusConfirmation({super.key, required this.titleKey, required this.messageKey, required this.actionKey});
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(titleKey.tr()), content: Text(messageKey.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: actionKey.tr(), onPressed: () => context.pop(true))]);
}