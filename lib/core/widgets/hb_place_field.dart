import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';

class HBPlaceSuggestion<T> {
  final T value;
  final String title;
  final String? subtitle;

  const HBPlaceSuggestion({required this.value, required this.title, this.subtitle});
}

/// Shared debounced suggestion field for database and geocoding searches.
class HBPlaceField<T> extends StatefulWidget {
  final TextEditingController controller;
  final Future<List<HBPlaceSuggestion<T>>> Function(String query) search;
  final ValueChanged<T> onSelected;
  final String hint;
  final bool enabled;
  final int minimumCharacters;
  final Duration debounce;

  const HBPlaceField({super.key, required this.controller, required this.search, required this.onSelected, required this.hint, this.enabled = true, this.minimumCharacters = 2, this.debounce = const Duration(milliseconds: 300)});

  @override
  State<HBPlaceField<T>> createState() => _HBPlaceFieldState<T>();
}

class _HBPlaceFieldState<T> extends State<HBPlaceField<T>> {
  Timer? _timer;
  List<HBPlaceSuggestion<T>> _results = const [];
  bool _loading = false;

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _search(String value) {
    _timer?.cancel();
    if (value.trim().length < widget.minimumCharacters) { setState(() => _results = const []); return; }
    _timer = Timer(widget.debounce, () async {
      if (mounted) setState(() => _loading = true);
      try {
        final results = await widget.search(value.trim());
        if (mounted && widget.controller.text == value) setState(() => _results = results);
      } on AppException {
        if (mounted) setState(() => _results = const []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    HBInput(controller: widget.controller, enabled: widget.enabled, hint: widget.hint, prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _loading ? const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null, onChanged: _search),
    if (_results.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), HBTile(child: Column(children: [for (final result in _results) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.location_on_outlined), title: Text(result.title), subtitle: result.subtitle == null ? null : Text(result.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () { widget.controller.text = result.title; widget.onSelected(result.value); setState(() => _results = const []); })]))],
  ]);
}