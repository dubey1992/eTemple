import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/seo/page_metadata.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_settings.dart';
import '../../content/presentation/seo_scope.dart';
import '../../content/presentation/widgets/address_card.dart';
import '../../temple/data/temple_providers.dart';
import '../../temple/domain/temple_profile.dart';
import '../data/enquiry_providers.dart';
import '../domain/enquiry.dart';
import 'widgets/enquiry_form_card.dart';

/// The prototype's `संपर्क` section as its own page: how to reach the temple,
/// and a form for writing to it.
///
/// The address is shown first and the form second, deliberately. Most people
/// arriving here want a telephone number, and a villager who can simply ring
/// the temple should not have to fill in a form to find that out.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final templeName = ref.watch(templeNameProvider);
    final settings = ref.watch(siteSettingsProvider);
    final profile = ref.watch(templeProfileProvider);

    return SeoScope(
      title: PageMetadata.compose(
        pageTitle: l10n.contactPageTitle,
        siteName: templeName ?? l10n.appTitle,
      ),
      description: l10n.contactPageSubtitle,
      canonicalPath: RoutePaths.contact,
      child: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contactPageTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.contactPageSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(l10n.contactOtherWays, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              // The address must never take the form down: a profile that
              // failed to load shows its own empty state, and the form below is
              // still usable.
              AddressCard(
                address: profile.value?.address ?? TempleAddress.empty,
                contact: settings.value?.contact ?? const ContactInfo(),
              ),

              const SizedBox(height: AppSpacing.xxl),
              Text(l10n.contactFormTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),

              const _ContactForm(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// The form, and the two states it can end in.
///
/// Held separately from the page so a failure to fetch the anti-spam ticket
/// degrades this block alone — the address above it stays readable, which is
/// the information most visitors came for.
class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm();

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  EnquiryReceipt? _receipt;

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(enquiryFormProvider);

    final receipt = _receipt;
    if (receipt != null) {
      return _SentPanel(
        receipt: receipt,
        onSendAnother: () {
          setState(() => _receipt = null);
          // A ticket is spent once, so the next message needs a new one.
          ref.invalidate(enquiryFormProvider);
        },
      );
    }

    return form.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        error: error is AppException ? error : const AppException.unknown(),
        onRetry: () => ref.invalidate(enquiryFormProvider),
      ),
      data: (data) => EnquiryFormCard(
        key: const Key('contact-form'),
        form: data,
        onSubmitted: (receipt) => setState(() => _receipt = receipt),
      ),
    );
  }
}

/// What the visitor sees after sending: their reference, and a way to write
/// again without reloading the page.
class _SentPanel extends StatelessWidget {
  const _SentPanel({required this.receipt, required this.onSendAnother});

  final EnquiryReceipt receipt;
  final VoidCallback onSendAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: const Key('contact-sent'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.enquirySentTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.enquirySentBody, style: theme.textTheme.bodyMedium),

            // Null when the submission was dropped as spam. The visitor is
            // never told the difference — there is simply nothing to quote.
            if (receipt.reference != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.enquiryReferenceLabel}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextSpan(
                        text: receipt.reference,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              key: const Key('contact-send-another'),
              onPressed: onSendAnother,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.actionSendAnother),
            ),
          ],
        ),
      ),
    );
  }
}
