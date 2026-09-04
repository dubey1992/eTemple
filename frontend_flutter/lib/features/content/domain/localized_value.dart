import '../../../core/api/api_envelope.dart';

/// One piece of CMS text as the API resolved it for the requested language.
///
/// Mirrors `App\Support\LocalizedText` on the backend. [fallbackUsed] is the
/// contract that makes the bilingual rule honest: when a visitor asks for
/// English and only Hindi exists, the UI is told so it can say so, rather than
/// silently presenting Hindi as if it were the English version.
class LocalizedValue {
  const LocalizedValue({
    required this.value,
    required this.language,
    required this.fallbackUsed,
  });

  /// Parses the `{value, language, fallback_used}` block.
  ///
  /// Defensive on purpose: a missing block is an empty value, not a crash.
  factory LocalizedValue.fromJson(Object? json) {
    final map = ApiEnvelopeParser.asMap(json);
    if (map == null) return LocalizedValue.empty;

    final raw = map['value'];
    final text = raw is String && raw.trim().isNotEmpty ? raw : null;

    return LocalizedValue(
      value: text,
      language: map['language'] as String? ?? 'hi',
      fallbackUsed: map['fallback_used'] as bool? ?? false,
    );
  }

  static const LocalizedValue empty = LocalizedValue(
    value: null,
    language: 'hi',
    fallbackUsed: false,
  );

  /// The resolved text, or `null` when the committee has not written it yet.
  final String? value;

  /// The language actually served — not necessarily the one requested.
  final String language;

  /// True when the requested language was unavailable and Hindi was served.
  final bool fallbackUsed;

  bool get isEmpty => value == null;

  bool get isNotEmpty => value != null;

  /// The text, or [placeholder] when there is nothing to show.
  String orElse(String placeholder) => value ?? placeholder;

  /// The same value reduced to its first paragraph, for previews.
  ///
  /// Keeps the language and fallback flags, so an excerpt still reports that it
  /// was served as a Hindi fallback.
  LocalizedValue get firstParagraphOnly {
    final all = paragraphs;
    if (all.isEmpty) return this;
    return LocalizedValue(
      value: all.first,
      language: language,
      fallbackUsed: fallbackUsed,
    );
  }

  /// Content split into paragraphs on blank lines.
  ///
  /// Content is stored as plain text (see PHASE_1_PLAN assumption B6), so
  /// rendering is a matter of paragraph breaks, not HTML parsing.
  List<String> get paragraphs {
    final text = value;
    if (text == null) return const [];

    return text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
  }
}
