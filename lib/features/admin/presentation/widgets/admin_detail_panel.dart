import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';

/// Right-side admin detail drawer on web and full-page detail on mobile.
class AdminDetailPanel extends StatelessWidget {
  final String title;
  final Widget? status;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback onClose;

  const AdminDetailPanel({super.key, required this.title, this.status, required this.body, required this.actions, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;
    return Material(
      color: Colors.white,
      elevation: 20,
      child: SizedBox(
        width: mobile ? MediaQuery.sizeOf(context).width : 440,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 64, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Row(children: [Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleLarge?.withColor(LightModeColors.lightOnSurface).bold)), if (status != null) status!, const SizedBox(width: AppSpacing.sm), HBButton.icon(icon: Icons.close, onPressed: onClose, size: HBButtonSize.sm)]))),
              const Divider(height: 1),
              Expanded(child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [body])),
              const Divider(height: 1),
              Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.md), color: Colors.white, child: Wrap(alignment: WrapAlignment.end, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions)),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDetailOverlay extends StatelessWidget {
  final Widget panel;
  final VoidCallback onClose;
  const AdminDetailOverlay({super.key, required this.panel, required this.onClose});

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      children: [
        Positioned.fill(child: GestureDetector(onTap: onClose, child: ColoredBox(color: LightModeColors.lightShadow.withValues(alpha: 0.30)))),
        Align(
          alignment: Alignment.centerRight,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => FractionalTranslation(translation: Offset(value, 0), child: child),
            child: panel,
          ),
        ),
      ],
    ),
  );
}

class AdminDetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminDetailSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: context.textStyles.titleMedium?.withColor(LightModeColors.lightOnSurface).bold), const SizedBox(height: AppSpacing.sm), child]),
  );
}

class AdminLabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  const AdminLabelValueRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 40),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LightModeColors.lightDivider))),
    child: Row(children: [Expanded(child: Text(label, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), Flexible(child: Text(value, textAlign: TextAlign.end, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurface).semiBold))]),
  );
}