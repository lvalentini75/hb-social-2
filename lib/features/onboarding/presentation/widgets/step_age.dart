import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:intl/intl.dart';

class StepAge extends StatefulWidget {
  final DateTime? birthDate;
  final ValueChanged<DateTime> onChanged;

  const StepAge({super.key, required this.birthDate, required this.onChanged});

  @override
  State<StepAge> createState() => _StepAgeState();
}

class _StepAgeState extends State<StepAge> {
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.text = widget.birthDate == null ? '' : DateFormat.yMd(context.locale.toString()).format(widget.birthDate!);
  }

  @override
  void didUpdateWidget(covariant StepAge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birthDate != widget.birthDate && widget.birthDate != null) _controller.text = DateFormat.yMd(context.locale.toString()).format(widget.birthDate!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(context: context, initialDate: widget.birthDate ?? DateTime(now.year - 18, now.month, now.day), firstDate: DateTime(1900), lastDate: now, locale: context.locale);
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _pick(context),
    child: AbsorbPointer(child: HBInput(label: 'signup.birth_date'.tr(), hint: 'signup.birth_date_hint'.tr(), controller: _controller, enabled: false, prefixIcon: const Icon(Icons.cake_outlined, color: LightModeColors.lightOnSurfaceVariant))),
  );
}