import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/account.dart';

/// Turns the accounting API's codes and dates into text a treasurer can read.
///
/// Kept out of the widgets so the wording is decided once and can be unit
/// tested without pumping a screen.
///
/// There is deliberately **no money formatting here**. Amounts arrive from the
/// server already formatted, because the paise are the authority and only one
/// side of the wire should be dividing by a hundred (Phase 6's rule).
class AccountLabels {
  const AccountLabels._();

  static String type(AppLocalizations l10n, String code) => switch (code) {
    TransactionTypes.income => l10n.accountsTypeIncome,
    _ => l10n.accountsTypeExpense,
  };

  static String status(AppLocalizations l10n, String code) => switch (code) {
    TransactionStatuses.approved => l10n.accountsStatusApproved,
    TransactionStatuses.reversed => l10n.accountsStatusReversed,
    _ => l10n.accountsStatusPending,
  };

  /// `2026-06-15` → `15 जून 2026` / `15 June 2026`.
  ///
  /// The API sends a plain date and it is read as one: money moves on a day,
  /// and turning that into an instant would let a timezone shift it — the
  /// defect Phase 4 spent a red build finding.
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

  /// Rupees from paise, grouped the Indian way — ₹1,25,500.00.
  ///
  /// The one place on this side that divides by a hundred, and it exists only
  /// because the public transparency figures are **aggregates the server never
  /// formats**: it sends totals, not rows, and a total has no `_formatted`
  /// twin. Every individual amount still arrives formatted from the server.
  static String rupees(int paise) {
    final negative = paise < 0;
    final absolute = paise.abs();

    final whole = (absolute ~/ 100).toString();
    final fraction = (absolute % 100).toString().padLeft(2, '0');

    return '${negative ? '-' : ''}₹${_groupIndian(whole)}.$fraction';
  }

  /// 1234567 → "12,34,567": the last three digits, then pairs.
  ///
  /// Mirrors `App\Support\Money::groupIndian` deliberately — the village reads
  /// lakhs, not millions, and the published page and the printed receipt must
  /// group a figure the same way.
  static String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;

    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);

    final pairs = <String>[];
    while (rest.length > 2) {
      pairs.add(rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) pairs.add(rest);

    return '${pairs.reversed.join(',')},$last3';
  }
}
