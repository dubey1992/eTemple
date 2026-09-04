import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/language_switch.dart';
import '../../auth/presentation/auth_controller.dart';

/// Chrome for the protected admin area.
///
/// The navigation surface is intentionally minimal in Phase 0 — the dashboard,
/// user management and permission-aware menus are Phase 2.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isCompact = Breakpoints.of(context).isCompact;

    Future<void> signOut() async {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go(RoutePaths.home);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminDashboardTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
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
      body: SafeArea(child: child),
    );
  }
}
