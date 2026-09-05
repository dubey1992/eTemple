import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/routing/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../temple/domain/temple_profile.dart';
import '../../domain/site_settings.dart';

/// The hero band: the temple's name over the devotional maroon gradient.
///
/// Everything in it is CMS content — the name and locality from the temple
/// profile, the tagline from site settings — so an unconfigured site still
/// renders a coherent header rather than empty space.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.settings, required this.profile});

  final SiteSettings settings;
  final TempleProfile profile;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);
    final isWide = formFactor == FormFactor.desktop;

    final copy = _HeroCopy(settings: settings, profile: profile);

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(flex: 4, child: _HeroEmblem(profile: profile)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: AppSpacing.xl),
              _HeroEmblem(profile: profile),
            ],
          );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.settings, required this.profile});

  final SiteSettings settings;
  final TempleProfile profile;

  /// The hero paragraph is the profile's mission and nothing else. Falling
  /// back to the tagline would repeat the strip directly above it on any
  /// site that has a tagline and no mission yet.
  String? get _intro => profile.mission.value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The invocation, as the prototype's eyebrow pill.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Text(
            l10n.invocation,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          // The temple's own name, from the profile. The ARB string stands in
          // only until that request resolves.
          profile.name.orElse(l10n.appTitle),
          key: const Key('hero-title'),
          style:
              (isCompact
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.displaySmall)
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),

        // The prototype's hero paragraph, from the temple profile. CMS content,
        // so it simply does not appear until the committee writes it.
        if (_intro != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _intro!,
            key: const Key('hero-tagline'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        // Wrapped so two buttons never overflow a narrow phone.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            // Donate is the primary action in the approved design, and it was
            // missing here entirely: the hero of a temple that runs on the
            // village's contributions asked people to look at the calendar.
            FilledButton.icon(
              key: const Key('hero-donate'),
              onPressed: () => context.go(RoutePaths.donate),
              icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
              label: Text(l10n.donateAction),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.onGold,
              ),
            ),
            FilledButton.icon(
              key: const Key('hero-events'),
              onPressed: () => context.go(RoutePaths.events),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(l10n.viewEvents),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.maroon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The panel beside the hero copy: the temple's name and village over a
/// gradient.
///
/// Drawn rather than photographed: the committee has no approved photograph
/// yet, and a placeholder image would be invented temple content. The caption
/// under the emblem is the profile's, so it appears only once the committee has
/// filled it in.
class _HeroEmblem extends StatelessWidget {
  const _HeroEmblem({required this.profile});

  final TempleProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;
    // The caption is the temple's own name and where it stands, both from the
    // profile. Nothing here is written into the app.
    final name = profile.name.value;
    final locality = profile.address.village;

    return Container(
      height: isCompact ? 180 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppColors.panelShadow,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDD85), Color(0xFFF3A73E), Color(0xFFA93351)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.temple_hindu_outlined,
              size: isCompact ? 64 : 96,
              color: const Color(0xFF5C2115),
            ),
            if (name != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                name,
                key: const Key('hero-emblem-name'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF5C2115),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (locality != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                locality,
                key: const Key('hero-emblem-locality'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6E3423),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
