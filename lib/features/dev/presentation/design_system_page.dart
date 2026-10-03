import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/providers/admin_preview_provider.dart';

/// Developer-only gallery of every design token and HB* widget, reachable at
/// `/dev/design-system` in debug builds. Labels here are intentionally not
/// translated: this page never ships to users.
class DesignSystemPage extends ConsumerStatefulWidget {
  const DesignSystemPage({super.key});

  @override
  ConsumerState<DesignSystemPage> createState() => _DesignSystemPageState();
}

class _DesignSystemPageState extends ConsumerState<DesignSystemPage> {
  int _tabIndex = 0;
  bool _chipSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightModeColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Design System'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/')),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const _Section(title: 'Colors', child: _ColorSwatches()),
              const _Section(title: 'Typography', child: _TypeScale()),
              const _Section(title: 'Radius', child: _RadiusSamples()),
              const _Section(title: 'Shadows', child: _ShadowSamples()),
              _Section(
                title: 'HBButton',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HBButton.primary(label: 'Primary md', onPressed: () {}),
                    HBButton.secondary(label: 'Secondary md', onPressed: () {}),
                    HBButton.soft(label: 'Soft md', onPressed: () {}),
                    HBButton.ghost(label: 'Ghost md', onPressed: () {}),
                    HBButton.icon(icon: Icons.favorite_border_rounded, onPressed: () {}),
                    HBButton.primary(label: 'Primary sm', size: HBButtonSize.sm, onPressed: () {}),
                    HBButton.secondary(label: 'Secondary sm', size: HBButtonSize.sm, onPressed: () {}),
                    HBButton.soft(label: 'Soft sm', size: HBButtonSize.sm, onPressed: () {}),
                    HBButton.ghost(label: 'Ghost sm', size: HBButtonSize.sm, onPressed: () {}),
                    HBButton.icon(icon: Icons.more_horiz_rounded, size: HBButtonSize.sm, onPressed: () {}),
                    HBButton.primary(label: 'Loading', isLoading: true, onPressed: () {}),
                    const HBButton.primary(label: 'Disabled', onPressed: null),
                    HBButton.primary(label: 'With icon', icon: Icons.add_rounded, onPressed: () {}),
                  ],
                ),
              ),
              const _Section(
                title: 'HBInput',
                child: Column(
                  children: [
                    HBInput(label: 'Label', hint: 'Hint text'),
                    SizedBox(height: AppSpacing.md),
                    HBInput(
                      label: 'With prefix',
                      hint: 'email@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
                    ),
                    SizedBox(height: AppSpacing.md),
                    HBInput(label: 'Password', hint: '••••••••', obscureText: true),
                    SizedBox(height: AppSpacing.md),
                    HBInput(label: 'With error', hint: 'Hint', errorText: 'Questo campo è obbligatorio'),
                  ],
                ),
              ),
              _Section(
                title: 'HBChip',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    HBChip(label: 'Selected', selected: _chipSelected, onTap: () => setState(() => _chipSelected = !_chipSelected)),
                    HBChip(label: 'Unselected', selected: !_chipSelected, onTap: () => setState(() => _chipSelected = !_chipSelected)),
                    const HBChip(label: 'With icon', selected: true, icon: Icons.pets_rounded),
                    const HBChip(label: 'With icon', selected: false, icon: Icons.pets_rounded),
                  ],
                ),
              ),
              _Section(
                title: 'HBSegmentedTabs',
                child: HBSegmentedTabs(
                  labels: const ['Per te', 'Seguiti', 'Vicino'],
                  selectedIndex: _tabIndex,
                  onChanged: (index) => setState(() => _tabIndex = index),
                ),
              ),
              _Section(
                title: 'HBAvatar',
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    HBAvatar(name: 'Marco Rossi', avatarSize: HBAvatarSize.xs),
                    HBAvatar(name: 'Marco Rossi', avatarSize: HBAvatarSize.sm),
                    HBAvatar(name: 'Marco Rossi', avatarSize: HBAvatarSize.md),
                    HBAvatar(name: 'Marco Rossi', avatarSize: HBAvatarSize.lg),
                    HBAvatar(name: 'Marco Rossi', avatarSize: HBAvatarSize.xl),
                    HBAvatar(isGuest: true, avatarSize: HBAvatarSize.lg),
                    HBAvatar(name: 'Luca Bianchi', avatarSize: HBAvatarSize.lg, ringColor: LightModeColors.lightPrimaryOutline),
                    HBAvatar(name: 'Luca Bianchi', avatarSize: HBAvatarSize.lg, showOnlineDot: true),
                  ],
                ),
              ),
              const _Section(
                title: 'HBBadge',
                child: Wrap(
                  spacing: AppSpacing.md,
                  children: [
                    HBBadge(kind: HBBadgeKind.verified),
                    HBBadge(kind: HBBadgeKind.gunShop),
                    HBBadge(kind: HBBadgeKind.guide),
                    HBBadge(kind: HBBadgeKind.association),
                  ],
                ),
              ),
              const _Section(
                title: 'HBStatusChip',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    HBStatusChip(kind: HBStatusKind.approved, label: 'Approvato'),
                    HBStatusChip(kind: HBStatusKind.pending, label: 'In attesa'),
                    HBStatusChip(kind: HBStatusKind.rejected, label: 'Rifiutato'),
                    HBStatusChip(kind: HBStatusKind.info, label: 'Info'),
                    HBStatusChip(kind: HBStatusKind.neutral, label: 'Neutro'),
                    HBStatusChip(kind: HBStatusKind.moderator, label: 'Moderatore'),
                    HBStatusChip(kind: HBStatusKind.admin, label: 'Admin'),
                    HBStatusChip(kind: HBStatusKind.superAdmin, label: 'Super admin'),
                  ],
                ),
              ),
              const _Section(
                title: 'HBSkeleton',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HBSkeleton(height: 40, width: 40, radius: AppRadius.pill),
                    SizedBox(height: AppSpacing.sm),
                    HBSkeleton(height: 12, width: 220),
                    SizedBox(height: AppSpacing.sm),
                    HBSkeleton(height: 120, radius: AppRadius.sm),
                  ],
                ),
              ),
              _Section(
                title: 'HBEmptyState',
                child: HBCard(
                  child: HBEmptyState(
                    icon: Icons.dynamic_feed_outlined,
                    title: 'Nessun contenuto',
                    message: 'Una riga di testo che spiega cosa comparirà qui.',
                    action: HBButton.primary(label: 'Azione', onPressed: () {}),
                  ),
                ),
              ),
              const _Section(
                title: 'HBCard',
                child: HBCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('Superficie bianca, raggio 22, ombra level1, nessun bordo.'),
                ),
              ),
              _Section(
                title: 'Anteprime debug (debugPreview=true, tutti i campi null)',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    HBButton.secondary(label: 'Anteprima dettaglio gruppo', onPressed: () => context.go('/groups/preview?debugPreview=true')),
                    HBButton.secondary(label: 'Anteprima chat', onPressed: () => context.go('/messages/preview?debugPreview=true')),
                    HBButton.secondary(label: 'Anteprima profilo', onPressed: () => context.go('/u/preview?debugPreview=true')),
                     HBButton.secondary(label: 'Anteprima annuncio', onPressed: () => context.go('/marketplace/preview?debugPreview=true')),
                     HBButton.secondary(label: 'Anteprima evento', onPressed: () => context.go('/events/preview?debugPreview=true')),
                     HBButton.secondary(label: 'Anteprima uscita', onPressed: () => context.go('/hunting/diary/preview?debugPreview=true')),
                     HBButton.secondary(label: 'Anteprima mappa', onPressed: () => context.go('/hunting/map')),
                     HBButton.secondary(label: 'Anteprima cane', onPressed: () => context.go('/hunting/dogs/preview?debugPreview=true')),
                  ],
                ),
              ),
               _Section(
                 title: 'Console admin',
                 child: Wrap(
                   spacing: AppSpacing.sm,
                   runSpacing: AppSpacing.sm,
                   children: [
                     HBButton.secondary(label: 'Pannello utente', onPressed: () => _openAdminPreview('/admin/users?panel=user')),
                     HBButton.secondary(label: 'Pannello segnalazione', onPressed: () => _openAdminPreview('/admin/reports?panel=report')),
                     HBButton.secondary(label: 'Pannello richiesta badge', onPressed: () => _openAdminPreview('/admin/badges?panel=badge')),
                      HBButton.secondary(label: 'Anteprima approvazione', onPressed: () => _openAdminPreview('/admin/approvals?panel=approval')),
                      HBButton.secondary(label: 'Anteprima calendario', onPressed: () => _openAdminPreview('/admin/calendars?panel=calendar')),
                      HBButton.secondary(label: 'Ruoli e permessi', onPressed: () => _openAdminPreview('/admin/roles')),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdminPreview(String location) {
    if (!Env.previewEnabled) return;
    ref.read(adminPreviewProvider.notifier).state = true;
    context.go(location);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  static const List<(String, Color)> _tokens = [
    ('page', LightModeColors.lightBackground),
    ('surface', LightModeColors.lightSurface),
    ('soft', LightModeColors.lightBackgroundSoft),
    ('hover', LightModeColors.lightBackgroundHover),
    ('divider', LightModeColors.lightDivider),
    ('border', LightModeColors.lightBorder),
    ('text', LightModeColors.lightOnSurface),
    ('textSecondary', LightModeColors.lightOnSurfaceVariant),
    ('textTertiary', LightModeColors.lightTextTertiary),
    ('primary', LightModeColors.lightPrimary),
    ('primaryDeep', LightModeColors.lightForest),
    ('primarySoft', LightModeColors.lightPrimarySoft),
    ('primaryOutline', LightModeColors.lightPrimaryOutline),
    ('success', LightModeColors.lightSuccess),
    ('warning', LightModeColors.lightWarning),
    ('error', LightModeColors.lightError),
    ('info', LightModeColors.lightInfo),
    ('adminSidebar', LightModeColors.adminSidebar),
  ];

  static String _hex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _tokens
          .map(
            (token) => SizedBox(
              width: 150,
              child: HBCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: token.$2, borderRadius: BorderRadius.circular(AppRadius.xs)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(token.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium),
                          Text(_hex(token.$2), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final samples = <(String, TextStyle?)>[
      ('headlineLarge', styles.headlineLarge),
      ('headlineMedium', styles.headlineMedium),
      ('headlineSmall', styles.headlineSmall),
      ('titleLarge', styles.titleLarge),
      ('titleMedium', styles.titleMedium),
      ('titleSmall', styles.titleSmall),
      ('bodyLarge', styles.bodyLarge),
      ('bodyMedium', styles.bodyMedium),
      ('bodySmall', styles.bodySmall),
      ('labelLarge', styles.labelLarge),
      ('labelMedium', styles.labelMedium),
      ('labelSmall', styles.labelSmall),
    ];
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: samples
            .map(
              (sample) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('${sample.$1} — Caccia al cinghiale', style: sample.$2),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RadiusSamples extends StatelessWidget {
  const _RadiusSamples();

  @override
  Widget build(BuildContext context) {
    const values = <(String, double)>[
      ('xs 10', AppRadius.xs),
      ('sm 14', AppRadius.sm),
      ('md 18', AppRadius.md),
      ('lg 22', AppRadius.lg),
      ('xl 28', AppRadius.xl),
      ('pill 999', AppRadius.pill),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values
          .map(
            (value) => Container(
              width: 110,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LightModeColors.lightPrimarySoft,
                borderRadius: BorderRadius.circular(value.$2),
              ),
              child: Text(value.$1, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightForest)),
            ),
          )
          .toList(),
    );
  }
}

class _ShadowSamples extends StatelessWidget {
  const _ShadowSamples();

  @override
  Widget build(BuildContext context) {
    const levels = <(String, List<BoxShadow>)>[
      ('level1', AppShadows.level1),
      ('level2', AppShadows.level2),
      ('level3', AppShadows.level3),
    ];
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: levels
          .map(
            (level) => Container(
              width: 150,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: level.$2),
              child: Text(level.$1, style: context.textStyles.labelMedium),
            ),
          )
          .toList(),
    );
  }
}
