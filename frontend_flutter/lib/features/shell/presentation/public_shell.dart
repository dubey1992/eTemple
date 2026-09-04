import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/language_switch.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_settings.dart';
import '../../temple/data/temple_providers.dart';

/// Chrome shared by every public page: header, admin-configured navigation,
/// language switch and footer.
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
        toolbarHeight: isCompact ? 64 : 76,
        title: InkWell(
          onTap: () => context.go(RoutePaths.home),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                templeName,
                key: const Key('shell-temple-name'),
                style: theme.textTheme.titleLarge,
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
            TextButton(
              onPressed: () => context.go(destination),
              child: Text(actionLabel),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
      drawer: (!formFactor.isDesktop && navigation.isNotEmpty)
          ? _NavigationDrawer(items: navigation)
          : null,
      body: SafeArea(child: child),
      bottomNavigationBar: const _PublicFooter(),
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
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Consumer(
                builder: (context, ref, _) => Text(
                  ref.watch(templeNameProvider) ?? context.l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
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
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Text(
            footer,
            key: const Key('public-footer'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
