import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/language_switch.dart';
import '../../../core/widgets/page_container.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_settings.dart';
import '../../temple/data/temple_providers.dart';

/// Chrome shared by every public page: an information strip, the header with
/// admin-configured navigation, the language switch and the footer.
///
/// The temple's name, the locality beneath it, the menu and the footer all come
/// from the CMS, so the committee can change them without a code release. If
/// those requests fail the shell degrades — the app's own name stands in for the
/// temple's, the locality line disappears and the menu is empty — rather than
/// blocking the page the visitor came to read.
class PublicShell extends ConsumerWidget {
  const PublicShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formFactor = Breakpoints.of(context);
    final isCompact = formFactor.isCompact;
    final isSignedIn = ref.watch(isAuthenticatedProvider);
    final navigation = ref.watch(navigationProvider);
    // The temple's own name, authoritative from the profile since Phase 3. The
    // ARB string is the shell fallback shown only until the profile resolves.
    final templeName = ref.watch(templeNameProvider) ?? l10n.appTitle;
    // No fallback for the locality: a village name is temple content, so an
    // unconfigured profile simply shows no second line.
    final locality = ref.watch(templeLocalityProvider);

    final destination = isSignedIn ? RoutePaths.admin : RoutePaths.login;
    final actionLabel = isSignedIn ? l10n.navAdmin : l10n.signIn;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        toolbarHeight: isCompact ? 68 : 80,
        title: InkWell(
          onTap: () => context.go(RoutePaths.home),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandMark(),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      templeName,
                      key: const Key('shell-temple-name'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact && locality != null)
                      Text(
                        locality,
                        key: const Key('shell-temple-locality'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // The configured menu only fits beside the title on wide screens; on
          // anything narrower it moves into the drawer.
          if (formFactor.isDesktop)
            for (final item in navigation)
              _NavButton(key: Key('nav-${item.id}'), item: item),

          LanguageSwitch(compact: isCompact),
          if (isCompact)
            IconButton(
              onPressed: () => context.go(destination),
              icon: Icon(
                isSignedIn ? Icons.dashboard_outlined : Icons.login_outlined,
              ),
              tooltip: actionLabel,
            )
          else ...[
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () => context.go(destination),
              child: Text(actionLabel),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
      drawer: (!formFactor.isDesktop && navigation.isNotEmpty)
          ? _NavigationDrawer(items: navigation)
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!isCompact) const _InfoStrip(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: const _PublicFooter(),
    );
  }
}

/// The circular gold emblem beside the temple's name.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, Color(0xFFFFDF86)],
        ),
      ),
      child: const Icon(
        Icons.temple_hindu,
        size: 24,
        color: AppColors.maroonDeep,
      ),
    );
  }
}

/// The dark strip above the page, carrying the prototype's two lines: what this
/// place is on the left, where it is on the right.
///
/// Distinct from the hero paragraph directly below it, which is the temple
/// profile's mission. Both halves are CMS content, so the strip disappears
/// entirely on a site the committee has not configured rather than showing
/// invented copy.
class _InfoStrip extends ConsumerWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final tagline = ref.watch(siteSettingsProvider).value?.tagline.value;

    // The short form, in the visitor's language. This used to be every address
    // line joined with commas, which on a Hindi page read
    // `Amarpur Pankhoriya, Kurma, Rasulpur Ekchari, Bhagalpur, Bihar, 813204` —
    // the wrong language, in the first line of the site.
    final where = ref.watch(templeProfileProvider).value?.address.shortLine;

    if (tagline == null && where == null) return const SizedBox.shrink();

    final style = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.86),
    );

    return Material(
      color: AppColors.maroonInk,
      child: PageContainer(
        maxWidth: 1120,
        verticalPadding: AppSpacing.sm,
        child: Row(
          children: [
            if (tagline != null)
              Expanded(
                // The two emblems are the approved design's, and they are
                // decoration rather than content: they say "temple" and "this
                // is where it is" without asking the committee to type them.
                child: Text(
                  '🙏 $tagline',
                  key: const Key('info-strip-tagline'),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (where != null) ...[
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  '📍 $where',
                  key: const Key('info-strip-address'),
                  style: style,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({super.key, required this.item});

  final NavigationEntry item;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      // External links are not pushed onto the in-app router; Phase 1 has no
      // URL launcher dependency, so they are simply not actionable yet.
      onPressed: item.isExternal ? null : () => context.go(item.route),
      child: Text(item.label.orElse(item.route)),
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({required this.items});

  final List<NavigationEntry> items;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Consumer(
                builder: (context, ref, _) => Text(
                  ref.watch(templeNameProvider) ?? context.l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            for (final item in items)
              ListTile(
                key: Key('drawer-nav-${item.id}'),
                title: Text(item.label.orElse(item.route)),
                enabled: !item.isExternal,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.route);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// The dark footer that closes the page.
///
/// The approved design's three columns — what this place is, the quick links,
/// and where it is — over a copyright line. Every part is admin-managed: the
/// paragraph and the links from site settings, the name and the address from
/// the temple profile, and the year from the clock.
///
/// It stays a pinned bar rather than the tall block the design draws, because
/// every public page owns its own scroll view and a footer inside the shell
/// cannot scroll away. So the columns are kept to two lines each, and on a
/// phone they collapse: the links are already in the drawer, and repeating
/// seven of them would push the page itself off the screen.
class _PublicFooter extends ConsumerWidget {
  const _PublicFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDesktop = Breakpoints.of(context).isDesktop;
    final settings = ref.watch(siteSettingsProvider).value;
    final templeName = ref.watch(templeNameProvider);
    final navigation = ref.watch(navigationProvider);
    final address = ref.watch(templeProfileProvider).value?.address;
    final village = address?.village;

    // The design's copyright line names the temple and its village, and
    // nothing else — not the panchayat the header carries.
    final identity = [templeName ?? l10n.appTitle, ?village].join(', ');
    final footer = settings?.footerText.value;

    return Material(
      color: AppColors.maroonFooter,
      child: SafeArea(
        top: false,
        child: PageContainer(
          maxWidth: 1120,
          verticalPadding: AppSpacing.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _FooterColumn(
                        key: const Key('public-footer'),
                        heading: templeName ?? l10n.appTitle,
                        lines: [?footer],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      flex: 3,
                      // The same admin-managed menu as the header, so the
                      // committee never has to remember to change two lists.
                      child: _QuickLinks(items: navigation),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      flex: 3,
                      child: _FooterColumn(
                        heading: l10n.footerContact,
                        lines: [?address?.shortLine],
                      ),
                    ),
                  ],
                )
              else
                _FooterColumn(
                  key: const Key('public-footer'),
                  heading: templeName ?? l10n.appTitle,
                  lines: [?footer, ?address?.shortLine],
                ),

              const SizedBox(height: AppSpacing.sm),
              Divider(
                height: AppSpacing.md,
                color: AppColors.onFooter.withValues(alpha: 0.18),
              ),
              Text(
                // The year is read from the clock rather than written into the
                // app, so the site does not silently claim to be a year old.
                l10n.footerCopyright('${DateTime.now().year}', identity),
                key: const Key('public-footer-copyright'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onFooter.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One column of the footer: a heading over one or two lines.
class _FooterColumn extends StatelessWidget {
  const _FooterColumn({super.key, required this.heading, required this.lines});

  final String heading;

  /// Nulls are already filtered out by the caller's `?` elements, so an
  /// unconfigured site simply shows a heading with nothing under it — or, when
  /// that is all there is, nothing at all.
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.onFooter,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final line in lines) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            line,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onFooter.withValues(alpha: 0.82),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// The footer's link column, from the admin-managed navigation.
class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.items});

  final List<NavigationEntry> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.footerQuickLinks,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.onFooter,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final item in items)
              // External entries are not pushed onto the in-app router, exactly
              // as in the header.
              InkWell(
                key: Key('footer-nav-${item.id}'),
                onTap: item.isExternal ? null : () => context.go(item.route),
                child: Text(
                  item.label.orElse(item.route),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onFooter.withValues(alpha: 0.82),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
