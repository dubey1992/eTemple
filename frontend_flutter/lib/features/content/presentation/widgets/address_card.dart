import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/site_settings.dart';

/// The temple's address and contact details.
///
/// Phase 1 renders this from site settings; Phase 3 moves the data to the
/// authoritative temple profile without changing this presentation.
class AddressCard extends StatelessWidget {
  const AddressCard({super.key, required this.contact});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (contact.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.addressComingSoon,
            key: const Key('address-empty'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Card(
      key: const Key('address-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in contact.addressLines) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (line == contact.addressLines.first)
                    Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(line, style: theme.textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            if (contact.phone != null)
              _DetailRow(
                icon: Icons.call_outlined,
                label: l10n.contactPhone,
                value: contact.phone!,
              ),
            if (contact.email != null)
              _DetailRow(
                icon: Icons.mail_outline,
                label: l10n.contactEmail,
                value: contact.email!,
              ),

            if (contact.mapUrl != null) ...[
              const SizedBox(height: AppSpacing.md),
              // Rendered as plain text rather than a launcher: opening external
              // URLs is not a Phase 1 requirement and url_launcher is not a
              // dependency yet.
              Text(
                '${l10n.contactMap}: ${contact.mapUrl}',
                key: const Key('address-map'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(text: value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
