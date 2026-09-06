import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/language_switch.dart';
import '../../auth/presentation/auth_controller.dart';
import 'admin_breadcrumbs.dart';
import 'admin_menu.dart';

/// Chrome for the protected admin area.
///
/// Since Phase 8 it carries a **side menu**: on a wide screen a fixed rail
/// beside the content, on a phone a drawer behind the app bar's menu button.
/// Before that, every switch between modules cost a round trip to the dashboard
/// and back, which with eleven modules had stopped scaling (PHASE_8_PLAN §9).
///
/// The breadcrumb trail stays. It answers a different question: the menu says
/// which module, the trail says how deep — and without it a deep link or a hard
/// refresh leaves no way back to the list but the browser's own button.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  /// Wide enough for a rail and a usable column of content beside it. Below
  /// this the menu becomes a drawer rather than squeezing both.
  static const double railBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isCompact = Breakpoints.of(context).isCompact;
    final location = GoRouterState.of(context).uri.path;
    final showRail = MediaQuery.sizeOf(context).width >= railBreakpoint;

    Future<void> signOut() async {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go(RoutePaths.home);
    }

    final content = Column(
      children: [
        AdminBreadcrumbs(location: location),
        Expanded(child: child),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminDashboardTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // The way back to the public site. Signing out used to be the only
          // exit from the console, so an administrator who wanted to check how
          // a change actually looks had to end their session to see it — or
          // edit the URL. The session is kept; the public header carries the
          // matching Administration button for the return trip.
          if (isCompact)
            IconButton(
              key: const Key('admin-view-site'),
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.home_outlined),
              tooltip: l10n.viewSite,
            )
          else ...[
            TextButton.icon(
              key: const Key('admin-view-site'),
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.home_outlined, size: 18),
              label: Text(l10n.viewSite),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          LanguageSwitch(compact: isCompact),
          if (isCompact)
            IconButton(
              onPressed: signOut,
              icon: const Icon(Icons.logout),
              tooltip: l10n.signOut,
            )
          else ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              onPressed: signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.signOut),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
      // Only when the rail is not showing, so a wide screen has no hamburger
      // for a menu that is already on it.
      drawer: showRail
          ? null
          : Drawer(
              key: const Key('admin-menu-drawer'),
              child: SafeArea(
                child: AdminMenu(
                  location: location,
                  onNavigate: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
      body: SafeArea(
        child: showRail
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const Key('admin-menu-rail'),
                    width: 232,
                    child: AdminMenu(location: location),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
    );
  }
}
