import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/donation.dart';

/// Turns the donation API's codes and dates into text a treasurer can read.
///
/// Kept out of the widgets so the wording is decided once and can be unit
/// tested without pumping a screen.
///
/// There is deliberately **no money formatting here**. Amounts arrive from the
/// server already formatted, because the paise are the authority and only one
/// side of the wire should be dividing by a hundred.
class DonationFormatting {
  const DonationFormatting._();

  static String modeLabel(String mode, AppLocalizations l10n) => switch (mode) {
    PaymentModes.cash => l10n.modeCash,
    PaymentModes.upi => l10n.modeUpi,
    PaymentModes.bankTransfer => l10n.modeBankTransfer,
    PaymentModes.cheque => l10n.modeCheque,
    PaymentModes.card => l10n.modeCard,
    _ => l10n.modeOther,
  };

  static String purposeLabel(String purpose, AppLocalizations l10n) =>
      switch (purpose) {
        DonationPurposes.general => l10n.purposeGeneral,
        DonationPurposes.puja => l10n.purposePuja,
        DonationPurposes.maintenance => l10n.purposeMaintenance,
        DonationPurposes.festival => l10n.purposeFestival,
        DonationPurposes.annadan => l10n.purposeAnnadan,
        DonationPurposes.construction => l10n.purposeConstruction,
        _ => l10n.purposeOther,
      };

  static String statusLabel(String status, AppLocalizations l10n) =>
      switch (status) {
        DonationStatuses.confirmed => l10n.statusConfirmed,
        DonationStatuses.reversed => l10n.statusReversed,
        _ => l10n.statusPending,
      };

  /// `2026-06-15` → `15 जून 2026` / `15 June 2026`.
  ///
  /// The API sends a plain date, and it is read as one: a donation happens on a
  /// day, and turning it into an instant would let a timezone move it — which
  /// is the defect Phase 4 spent a red build finding.
  static String date(String isoDate, String language) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;

    return DateFormat.yMMMd(language).format(parsed);
  }

  /// The same, for an instant the server sent with an offset.
  static String timestamp(String? iso, String language) {
    if (iso == null) return '—';

    final withoutZone = iso.replaceFirst(RegExp(r'(Z|[+-]\d{2}:?\d{2})$'), '');
    final parsed = DateTime.tryParse(withoutZone);
    if (parsed == null) return iso;

    return DateFormat.yMMMd(language).add_jm().format(parsed);
  }
}
