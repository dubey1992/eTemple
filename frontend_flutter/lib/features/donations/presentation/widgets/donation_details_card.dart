import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../media/presentation/widgets/media_image.dart';
import '../../domain/donation.dart';

/// The approved prototype's donation card: an explanation on the left, the bank
/// box beneath it, and the QR code on the right.
///
/// Rebuilt from the design rather than approximated — the dashed gold border on
/// the box and the label/value rows inside it are what make it read as
/// something to copy details out of.
///
/// Every value is what the committee typed. Nothing here is invented, and an
/// unfilled detail is simply absent rather than shown as a placeholder: this is
/// where devotees' money goes, and a plausible-looking wrong account number is
/// the worst thing this page could contain.
class DonationDetailsCard extends StatelessWidget {
  const DonationDetailsCard({super.key, required this.details});

  final DonationDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isWide = Breakpoints.of(context).isDesktop;

    final rows = details.rows(
      upiLabel: l10n.fieldUpiId,
      bankLabel: l10n.fieldBankName,
      accountNameLabel: l10n.fieldAccountName,
      accountLabel: l10n.fieldAccountNumber,
      ifscLabel: l10n.fieldIfsc,
    );

    final explanation = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.donateHeading,
          key: const Key('donate-heading'),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          // The committee's own wording where they have written one, and the
          // prototype's approved sentence until they do.
          details.intro.orElse(l10n.donateSubtitle),
          key: const Key('donate-intro'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _BankBox(rows: rows),
        ],
        if (details.note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            details.note.value!,
            key: const Key('donate-note'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final qr = details.qrUrl == null
        ? null
        : _QrPanel(url: details.qrUrl!, label: l10n.donateQrLabel);

    return Card(
      key: const Key('donation-details-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: qr == null
            ? explanation
            : isWide
            // The prototype's two-column grid, and its proportions.
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: explanation),
                  const SizedBox(width: AppSpacing.xl),
                  qr,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  explanation,
                  const SizedBox(height: AppSpacing.lg),
                  Center(child: qr),
                ],
              ),
      ),
    );
  }
}

/// The prototype's dashed-border box of payment details.
///
/// Each row carries a copy button, because the alternative on a phone is
/// transcribing an IFSC code by eye — and a mistyped account number is a
/// donation that goes somewhere else.
class _BankBox extends StatelessWidget {
  const _BankBox({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      key: const Key('donate-bank-box'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.7),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.panelBorder),
                      ),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    rows[i].$1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      key: Key('donate-value-$i'),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('donate-copy-$i'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: rows[i].$2));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.donateCopied(rows[i].$1))),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: l10n.actionCopy,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The QR code, framed the way the prototype frames it.
class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 230,
          height: 230,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppColors.panelShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: MediaImage(
              key: const Key('donate-qr'),
              url: url,
              fit: BoxFit.contain,
              // A QR must be crisp: 230 logical pixels at up to 3×, and no
              // further, because a blurred one does not scan.
              cacheWidth: 690,
              error: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
