import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/seo/seo_metadata_service.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/presentation/seo_scope.dart';
import '../data/temple_providers.dart';
import 'widgets/committee_list.dart';

/// The public committee page.
///
/// Every member shown here is published, still serving, and shows only the
/// personal details the server was willing to send.
class CommitteeScreen extends ConsumerWidget {
  const CommitteeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final members = ref.watch(committeeProvider);
    final templeName = ref.watch(templeNameProvider);

    return SeoScope(
      // The site name comes from the temple profile; the ARB string is only the
      // shell fallback used while that request is still in flight.
      title: PageMetadata.compose(
        pageTitle: l10n.committeeTitle,
        siteName: templeName ?? l10n.appTitle,
      ),
      description: l10n.committeeSubtitle,
      canonicalPath: RoutePaths.committee,
      child: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.committeeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.committeeSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              members.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error is AppException
                      ? error
                      : const AppException.unknown(),
                  onRetry: () => ref.invalidate(committeeProvider),
                ),
                data: (data) => CommitteeList(members: data),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
