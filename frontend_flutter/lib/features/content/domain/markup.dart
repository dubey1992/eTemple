/// The small slice of Markdown the committee actually writes.
///
/// Page bodies are stored as plain text (PHASE_1_PLAN assumption B6) and were
/// rendered as plain text — one `Text` per paragraph. That held until somebody
/// wrote the About page in Markdown, which is what a person who has used any
/// other editor in the last decade does. The page then showed `## राधाकृष्ण
/// ठाकुरबाड़ी` and `**1975**` to every visitor, hashes and asterisks included.
///
/// The answer is to read what they wrote rather than to teach them not to write
/// it. This is a deliberately small subset — headings, bold, italic and bullet
/// lists — covering what is on the site today and the next thing somebody is
/// likely to type.
///
/// Three things are left out on purpose. **Links** would mean turning text the
/// committee pasted into something a visitor's browser follows, and `javascript:`
/// is a URL; that needs a decision about trust, not a parser. **Raw HTML** is
/// never interpreted, for the same reason. **Tables, images, quotes and code**
/// are absent because nothing on this site uses them, and an unused branch is an
/// untested one. Anything unsupported stays exactly as it was typed, visible —
/// which is honest, and is how the committee finds out it did not work.
library;

/// A run of text with its emphasis. The unit a line is made of.
class MarkupSpan {
  const MarkupSpan(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is MarkupSpan &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(text, bold, italic);

  @override
  String toString() =>
      'MarkupSpan("$text"${bold ? ", bold" : ""}${italic ? ", italic" : ""})';
}

/// One block of a body: a heading, a paragraph or a list.
sealed class MarkupBlock {
  const MarkupBlock();

  /// The block's text with every marker removed.
  String get plainText;
}

class MarkupHeading extends MarkupBlock {
  const MarkupHeading({required this.level, required this.spans});

  /// 1–6, as the number of leading `#`.
  final int level;
  final List<MarkupSpan> spans;

  @override
  String get plainText => spans.map((s) => s.text).join();
}

class MarkupParagraph extends MarkupBlock {
  const MarkupParagraph(this.spans);

  final List<MarkupSpan> spans;

  @override
  String get plainText => spans.map((s) => s.text).join();
}

class MarkupBullets extends MarkupBlock {
  const MarkupBullets(this.items);

  final List<List<MarkupSpan>> items;

  @override
  String get plainText =>
      items.map((i) => i.map((s) => s.text).join()).join(' ');
}

/// Reads the subset above out of a body of text.
class Markup {
  const Markup._();

  static final RegExp _heading = RegExp(r'^(#{1,6})\s+(.*)$');

  // A bullet needs the space: `*बोल्ड*` opening a line is emphasis, not a list,
  // and `-5 डिग्री` is a number.
  static final RegExp _bullet = RegExp(r'^[-*]\s+(.*)$');

  // Longest marker first, so `**` is never read as two italics.
  static final RegExp _emphasis = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');

  /// Parses a whole body into blocks. Blank lines separate them, as before.
  static List<MarkupBlock> parse(String? body) {
    final text = body?.trim();
    if (text == null || text.isEmpty) return const [];

    final blocks = <MarkupBlock>[];
    var paragraph = <String>[];
    var bullets = <List<MarkupSpan>>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      // Joined with the newline the author typed: the committee writes label
      // lines ("**स्थापना वर्ष:** 1975") one under another, and collapsing
      // those into a run-on sentence would lose their meaning.
      blocks.add(MarkupParagraph(spans(paragraph.join('\n'))));
      paragraph = [];
    }

    void flushBullets() {
      if (bullets.isEmpty) return;
      blocks.add(MarkupBullets(bullets));
      bullets = [];
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();

      if (line.isEmpty) {
        flushParagraph();
        flushBullets();
        continue;
      }

      final heading = _heading.firstMatch(line);
      if (heading != null) {
        flushParagraph();
        flushBullets();
        blocks.add(
          MarkupHeading(
            level: heading.group(1)!.length,
            spans: spans(heading.group(2)!.trim()),
          ),
        );
        continue;
      }

      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        bullets.add(spans(bullet.group(1)!.trim()));
        continue;
      }

      flushBullets();
      paragraph.add(line);
    }

    flushParagraph();
    flushBullets();

    return List.unmodifiable(blocks);
  }

  /// Splits one line into emphasised and plain runs.
  ///
  /// An unmatched marker is left where it is rather than swallowed: a lone
  /// asterisk in the middle of a sentence is punctuation, and deleting it would
  /// silently alter what the committee wrote.
  static List<MarkupSpan> spans(String line) {
    if (line.isEmpty) return const [];

    final out = <MarkupSpan>[];
    var cursor = 0;

    for (final match in _emphasis.allMatches(line)) {
      if (match.start > cursor) {
        out.add(MarkupSpan(line.substring(cursor, match.start)));
      }
      final strong = match.group(1);
      out.add(
        strong != null
            ? MarkupSpan(strong, bold: true)
            : MarkupSpan(match.group(2)!, italic: true),
      );
      cursor = match.end;
    }

    if (cursor < line.length) out.add(MarkupSpan(line.substring(cursor)));

    return List.unmodifiable(out);
  }

  /// The text with every marker removed, for places that cannot show style —
  /// a `<meta>` description, a card heading, a page title.
  static String plainText(String? body) =>
      parse(body).map((b) => b.plainText).join(' ').trim();

  /// True when a paragraph carries nothing but a heading.
  ///
  /// Used to find the lead prose of a page: a body that opens with its own
  /// title has a first paragraph that says nothing on its own.
  static bool isHeadingOnly(String paragraph) {
    final blocks = parse(paragraph);
    return blocks.isNotEmpty && blocks.every((b) => b is MarkupHeading);
  }
}
