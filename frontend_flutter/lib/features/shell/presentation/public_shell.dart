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

/// The dark strip above the page: where the temple is, and how to reach it.
///
/// Deliberately *not* the tagline: that already leads the hero directly below,
/// and saying it twice on one screen reads as a mistake. What a visitor cannot
/// get from the hero is the address and the phone number, so those go here.
///
/// Both halves are CMS content, so the strip disappears entirely on a site the
/// committee has not configured rather than showing invented copy.
class _InfoStrip extends ConsumerWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final address = ref
        .watch(templeProfileProvider)
        .value
        ?.address
        .lines(panchayatLabel: l10n.panchayatLabel);
    final where = (address == null || address.isEmpty)
        ? null
        : address.join(', ');

    final contact = ref.watch(siteSettingsProvider).value?.contact;
    final reach = [?contact?.phone, ?contact?.email].join('  ·  ');

    if (where == null && reach.isEmpty) return const SizedBox.shrink();

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
            if (where != null)
              Expanded(
                child: Text(
                  where,
                  key: const Key('info-strip-address'),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (reach.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  reach,
                  key: const Key('info-strip-contact'),
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
class _PublicFooter extends ConsumerWidget {
  const _PublicFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final settings = ref.watch(siteSettingsProvider).value;
    final templeName = ref.watch(templeNameProvider);
    final locality = ref.watch(templeLocalityProvider);

    // Falls back to the temple's own identity from the profile, and only then
    // to the application shell name.
    final identity = [templeName ?? l10n.appTitle, ?locality].join(' · ');
    final footer = settings?.footerText.value ?? identity;

    return Material(
      color: AppColors.maroonFooter,
      child: SafeArea(
        top: false,
        child: PageContainer(
          maxWidth: 1120,
          verticalPadding: AppSpacing.md,
          child: Text(
            footer,
            key: const Key('public-footer'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onFooter,
            ),
          ),
        ),
      ),
    );
  }
}
