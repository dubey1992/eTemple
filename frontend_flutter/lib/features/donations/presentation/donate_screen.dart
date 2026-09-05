import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/seo/page_metadata.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/presentation/seo_scope.dart';
import '../../temple/data/temple_providers.dart';
import '../data/donation_providers.dart';
import 'widgets/donation_details_card.dart';

/// The approved prototype's `दान` section as its own page.
///
/// It shows where to send money and nothing else — no donor list, no running
/// total, no "our latest donor". That is not an omission: donor detail reaches
/// no public endpoint at any status, and there is nowhere for it to come from
/// (PHASE_6_PLAN assumption N5). The transparency figures the prototype shows
/// beneath this block are Phase 9.
class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final details = ref.watch(donationDetailsProvider);
    final templeName = ref.watch(templeNameProvider);

    return SeoScope(
      title: PageMetadata.compose(
        pageTitle: l10n.donateTitle,
        siteName: templeName ?? l10n.appTitle,
      ),
      description: l10n.donateSubtitle,
      canonicalPath: RoutePaths.donate,
      child: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.donateTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.donateSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              details.when(
                loading: () => const LoadingView(),
                // Unreachable details are an empty state rather than an error:
                // this page must never suggest an account number it could not
                // load.
                error: (_, _) => const DonationDetailsUnavailable(),
                data: (data) => data == null
                    ? const DonationDetailsUnavailable()
                    : DonationDetailsCard(details: data),
              ),

              // "Where does my money go" is the question a donor is already
              // asking on this screen, so the answer is offered here rather
              // than left to be found in a menu (Phase 9).
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('donate-transparency-link'),
                  onPressed: () => context.go(RoutePaths.transparency),
                  icon: const Icon(Icons.account_balance_outlined, size: 18),
                  label: Text(l10n.transparencyTitle),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing published yet.
///
/// The prototype's own footnote says the demo values will be replaced with real
/// ones; until the committee enters them this says so, and says nothing else.
class DonationDetailsUnavailable extends StatelessWidget {
  const DonationDetailsUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.donateComingSoon,
                key: const Key('donate-coming-soon'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
