import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/event.dart';

/// Turns the API's codes and instants into text a devotee can read.
///
/// Kept out of the widgets so the wording is decided once and can be unit
/// tested without pumping a screen.
class EventFormatting {
  const EventFormatting._();

  static String typeLabel(String type, AppLocalizations l10n) => switch (type) {
    EventTypes.aarti => l10n.eventTypeAarti,
    EventTypes.bhajanKirtan => l10n.eventTypeBhajanKirtan,
    EventTypes.festival => l10n.eventTypeFestival,
    EventTypes.puja => l10n.eventTypePuja,
    _ => l10n.eventTypeOther,
  };

  static String recurrenceLabel(String recurrence, AppLocalizations l10n) =>
      switch (recurrence) {
        Recurrences.daily => l10n.recurrenceDaily,
        Recurrences.weekly => l10n.recurrenceWeekly,
        Recurrences.monthly => l10n.recurrenceMonthly,
        Recurrences.yearly => l10n.recurrenceYearly,
        _ => l10n.recurrenceNone,
      };

  /// ISO weekday (1 = Monday) to a short label.
  static String weekdayLabel(int isoWeekday, AppLocalizations l10n) =>
      switch (isoWeekday) {
        1 => l10n.weekdayMon,
        2 => l10n.weekdayTue,
        3 => l10n.weekdayWed,
        4 => l10n.weekdayThu,
        5 => l10n.weekdayFri,
        6 => l10n.weekdaySat,
        7 => l10n.weekdaySun,
        _ => '',
      };

  static String statusLabel(String status, AppLocalizations l10n) =>
      switch (status) {
        EventStatuses.published => l10n.statusPublished,
        EventStatuses.cancelled => l10n.statusCancelled,
        _ => l10n.statusDraft,
      };

  /// The date, written out for the active language.
  static String date(DateTime value, String languageCode) =>
      DateFormat.yMMMMd(languageCode).format(value);

  static String time(DateTime value, String languageCode) =>
      DateFormat.jm(languageCode).format(value);

  /// "12 October 2026, 6:30 pm – 9:00 pm", collapsing the end date when it is
  /// the same day, because repeating it reads as though the event ran twice.
  static String when(EventOccurrence occurrence, String languageCode) {
    final start = occurrence.startAt;
    final end = occurrence.endAt;
    final startText =
        '${date(start, languageCode)}, ${time(start, languageCode)}';

    if (end == null) return startText;

    return occurrence.spansMultipleDays
        ? '$startText – ${date(end, languageCode)}, ${time(end, languageCode)}'
        : '$startText – ${time(end, languageCode)}';
  }

  /// How the event repeats, including the named days for a weekly rule.
  static String? repeats(
    String recurrence,
    List<int> days,
    AppLocalizations l10n,
  ) {
    if (recurrence == Recurrences.none) return null;

    final label = recurrenceLabel(recurrence, l10n);
    if (recurrence != Recurrences.weekly || days.isEmpty) return label;

    final named = (days.toList()..sort())
        .map((d) => weekdayLabel(d, l10n))
        .where((d) => d.isNotEmpty)
        .join(', ');

    return named.isEmpty ? label : '$label · $named';
  }
}
