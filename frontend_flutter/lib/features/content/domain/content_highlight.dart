/// One card in a CMS body.
///
/// The approved design opens the About section with three cards — `हमारी
/// विरासत`, `ग्राम सहभागिता`, `सेवा और भक्ति` — each an emblem, a heading and a
/// sentence. A page body is plain text (PHASE_1_PLAN assumption B6), so the
/// question was where those three headings live.
///
/// They live in the body, as a convention the committee can see and use: a
/// paragraph shaped `<emoji> <heading> — <text>` is a card. Anything else stays
/// a paragraph. That keeps the cards editable from the CMS — a fourth one is a
/// new paragraph, not a release — without a schema change, and without a screen
/// that breaks when somebody writes ordinary prose.
///
/// The em dash is the separator because it is what the approved copy already
/// uses, and because a hyphen appears inside ordinary words.
class ContentHighlight {
  const ContentHighlight({
    required this.heading,
    required this.body,
    this.emblem,
  });

  /// The leading emoji, when the heading starts with one. Decoration: a card
  /// without one is a card, not an error.
  final String? emblem;
  final String heading;
  final String body;

  static const String _separator = ' — ';

  /// Reads one paragraph, or null when it is not shaped like a card.
  ///
  /// A heading is short by definition. The length cap is what stops an ordinary
  /// sentence that happens to contain an em dash from being promoted to a card
  /// heading and losing the rest of its paragraph.
  static ContentHighlight? parse(String paragraph) {
    final index = paragraph.indexOf(_separator);
    if (index <= 0) return null;

    final heading = paragraph.substring(0, index).trim();
    final body = paragraph.substring(index + _separator.length).trim();
    if (heading.isEmpty || body.isEmpty || heading.length > 40) return null;

    final emblem = _leadingEmblem(heading);

    return ContentHighlight(
      emblem: emblem,
      heading: emblem == null
          ? heading
          : heading.substring(emblem.length).trim(),
      body: body,
    );
  }

  /// Every paragraph that is a card, in order. Empty when none are.
  static List<ContentHighlight> parseAll(Iterable<String> paragraphs) => [
    for (final paragraph in paragraphs) ?parse(paragraph),
  ];

  /// The leading pictograph, if the heading opens with one.
  ///
  /// Matched by code point rather than by a list of emoji: the committee may
  /// pick any symbol, and an app that only knew about 🛕, 🤝 and 🪔 would drop
  /// the fourth one somebody chose.
  static String? _leadingEmblem(String heading) {
    final runes = heading.runes.toList();
    if (runes.isEmpty) return null;

    var length = 0;
    for (final rune in runes) {
      // Everything at or above U+2000 that is not ordinary text: the symbol,
      // pictograph and dingbat ranges, plus the variation selectors and
      // zero-width joiner that hold a compound emoji together.
      final isPictograph =
          (rune >= 0x1F000 && rune <= 0x1FAFF) ||
          (rune >= 0x2600 && rune <= 0x27BF) ||
          rune == 0x200D ||
          rune == 0xFE0F;
      if (!isPictograph) break;
      length += String.fromCharCode(rune).length;
    }

    return length == 0 ? null : heading.substring(0, length);
  }
}
