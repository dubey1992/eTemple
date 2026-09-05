import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/files/link_opener.dart';
import '../../../temple/domain/temple_profile.dart';
import '../../domain/site_settings.dart';

/// The temple's address and contact details.
///
/// Composed from two sources on purpose: the postal address belongs to the
/// temple profile (authoritative since Phase 3) and the phone and e-mail to
/// site settings. Joining them is a presentation concern, so it happens here
/// rather than by duplicating either record.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.contact,
    this.templeName,
    this.opener = const LinkOpener(),
  });

  final TempleAddress address;
  final ContactInfo contact;

  /// Printed above the address, as the approved design does, and used to aim
  /// the map link. Optional: an unconfigured site has no name to print.
  final String? templeName;

  /// Injected so a test can assert which link the map block opens without
  /// launching a browser tab.
  final LinkOpener opener;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final lines = address.lines(
      labels: AddressLabels(
        village: l10n.addressVillageLabel,
        panchayat: l10n.panchayatLabel,
        policeStation: l10n.addressPoliceStationLabel,
        district: l10n.addressDistrictLabel,
      ),
    );
    final mapDestination = address.mapDestination(templeName);

    if (lines.isEmpty && contact.isEmpty) {
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
            if (templeName != null) ...[
              Text(
                templeName!,
                key: const Key('address-temple-name'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final line in lines) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (line == lines.first)
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

            if (mapDestination != null) ...[
              const SizedBox(height: AppSpacing.md),
              // The approved design reserves a block here for the map. It opens
              // the committee's own link when they have set one, and otherwise
              // a map search for the address printed directly above — which is
              // the temple's own content, not an invented location.
              //
              // A third party, so it is opened with `open` and not `openOwn`.
              _MapBlock(
                key: const Key('address-map'),
                label: l10n.contactMap,
                onOpen: () => opener.open(mapDestination),
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

/// The map panel at the foot of the address card.
class _MapBlock extends StatelessWidget {
  const _MapBlock({super.key, required this.label, required this.onOpen});

  final String label;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place, size: 40, color: theme.colorScheme.secondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
