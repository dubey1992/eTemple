import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/seo/seo_metadata_service.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../shell/presentation/not_found_screen.dart';
import '../data/content_providers.dart';
import 'seo_scope.dart';
import 'widgets/content_widgets.dart';

/// A CMS page rendered at its own slug, e.g. `/about`.
///
/// Covers every state the specification requires of a public API-driven screen:
/// loading, success, empty (written but blank), error/offline with retry, and
/// not-found for an unknown or unpublished slug.
class PageScreen extends ConsumerWidget {
  const PageScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pageProvider(slug));

    return page.when(
      loading: () => const LoadingView(),
      error: (error, _) {
        final exception = error is AppException
            ? error
            : const AppException.unknown();

        // A draft or unknown slug is indistinguishable by design, and both mean
        // "there is no such page" to a visitor.
        if (exception.isNotFound) return const NotFoundScreen();

        return ErrorView(
          error: exception,
          onRetry: () => ref.invalidate(pageProvider(slug)),
        );
      },
      data: (data) {
        final l10n = context.l10n;
        final title = data.title.orElse(l10n.appTitle);

        return SeoScope(
          title: PageMetadata.compose(
            pageTitle: data.metaTitle.value ?? data.title.value,
            siteName: l10n.appTitle,
          ),
          description: data.metaDescription.value ?? data.content.value,
          canonicalPath: RoutePaths.page(slug),
          child: SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const Key('page-title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (data.usesFallback) ...[
                    const FallbackNotice(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  ContentBody(content: data.content),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
