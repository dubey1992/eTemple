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
              const Expanded(flex: 4, child: _HeroEmblem()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: AppSpacing.xl),
              const _HeroEmblem(),
            ],
          );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.settings, required this.profile});

  final SiteSettings settings;
  final TempleProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;
    final locality = profile.address.locality;

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

        // The village line is temple content: no fallback, it simply does not
        // appear until the committee fills in the address.
        if (locality != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            locality,
            key: const Key('hero-locality'),
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.gold),
          ),
        ],

        // The devotional tagline is CMS-managed; it simply does not appear
        // until the committee writes one.
        if (settings.tagline.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            settings.tagline.value!,
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
            FilledButton.icon(
              key: const Key('hero-events'),
              onPressed: () => context.go(RoutePaths.events),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(l10n.viewAllEvents),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.onGold,
              ),
            ),
            FilledButton.icon(
              key: const Key('hero-committee'),
              onPressed: () => context.go(RoutePaths.committee),
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Text(l10n.viewCommittee),
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

/// The decorative panel beside the hero copy.
///
/// Drawn rather than photographed: the committee has no approved photograph
/// yet, and a placeholder image would be invented temple content.
class _HeroEmblem extends StatelessWidget {
  const _HeroEmblem();

  @override
  Widget build(BuildContext context) {
    final isCompact = Breakpoints.of(context).isCompact;

    return Container(
      height: isCompact ? 180 : 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDD85), Color(0xFFF3A73E), Color(0xFFA93351)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.temple_hindu_outlined,
          size: isCompact ? 76 : 116,
          color: const Color(0xFF5C2115),
        ),
      ),
    );
  }
}
