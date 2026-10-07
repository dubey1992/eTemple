import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/features/content/domain/markup.dart';

/// The body the committee actually published, trimmed to the shapes that broke.
const _aboutPage = '''
## राधाकृष्ण ठाकुरबाड़ी, अमरपुर पंखोरिया

**राधाकृष्ण ठाकुरबाड़ी** की स्थापना वर्ष **1975** में की गई थी।

### प्रथम मूर्ति स्थापना — 1975 : स्वर्गीय श्री मेघु मंडल

**मूर्ति स्थापना:** स्वर्गीय श्री मेघु मंडल
**स्थापना वर्ष:** 1975
''';

void main() {
  group('Markup.parse', () {
    test('a heading is a heading, not a line beginning with hashes', () {
      final blocks = Markup.parse('## राधाकृष्ण ठाकुरबाड़ी');

      expect(blocks, hasLength(1));
      final heading = blocks.single as MarkupHeading;
      expect(heading.level, 2);
      expect(heading.plainText, 'राधाकृष्ण ठाकुरबाड़ी');
      // The symptom that was reported: the markers reaching the reader.
      expect(heading.plainText, isNot(contains('#')));
    });

    test('every heading level is read', () {
      for (var level = 1; level <= 6; level++) {
        final blocks = Markup.parse('${'#' * level} शीर्षक');
        expect((blocks.single as MarkupHeading).level, level);
      }
    });

    test('seven hashes is not a heading, because Markdown says six', () {
      expect(Markup.parse('####### शीर्षक').single, isA<MarkupParagraph>());
    });

    test('a hash with no space is not a heading', () {
      // Otherwise "#1 भक्त" loses its hash and gains a type scale.
      expect(Markup.parse('#1 भक्त').single, isA<MarkupParagraph>());
    });

    test('bold and italic are read, and the markers do not survive', () {
      final spans =
          (Markup.parse('**मोटा** और *तिरछा*').single as MarkupParagraph).spans;

      expect(spans, [
        const MarkupSpan('मोटा', bold: true),
        const MarkupSpan(' और '),
        const MarkupSpan('तिरछा', italic: true),
      ]);
    });

    test('a double marker is bold, never two italics', () {
      final spans =
          (Markup.parse('**॥ राधे राधे ॥**').single as MarkupParagraph).spans;
      expect(spans.single, const MarkupSpan('॥ राधे राधे ॥', bold: true));
    });

    test('an unmatched marker is left exactly where it was typed', () {
      // Deleting it would quietly change what the committee wrote.
      final paragraph = Markup.parse('5 * 3 फूल').single as MarkupParagraph;
      expect(paragraph.plainText, '5 * 3 फूल');
    });

    test('bullets become a list; a hyphenated number does not', () {
      final list = Markup.parse('- पहला\n- दूसरा').single as MarkupBullets;
      expect(list.items, hasLength(2));
      expect(list.items.first.single.text, 'पहला');

      expect(Markup.parse('-5 डिग्री').single, isA<MarkupParagraph>());
    });

    test('lines inside a paragraph keep their breaks', () {
      // The committee writes label lines under one another; running them
      // together would lose which value belongs to which label.
      final p =
          Markup.parse('**वर्ष:** 1975\n**अवधि:** 1975 – 2025').single
              as MarkupParagraph;
      expect(p.plainText, contains('\n'));
    });

    test('ordinary prose is unchanged and stays one paragraph', () {
      const prose = 'मंदिर की दैनिक आरती शाम 6:30 बजे होती है।';
      final blocks = Markup.parse(prose);
      expect(blocks.single, isA<MarkupParagraph>());
      expect(blocks.single.plainText, prose);
    });

    test('nothing in, nothing out', () {
      expect(Markup.parse(null), isEmpty);
      expect(Markup.parse('   \n\n  '), isEmpty);
    });

    test('the published About page parses into the blocks it looks like', () {
      final blocks = Markup.parse(_aboutPage);

      expect(blocks.map((b) => b.runtimeType).toList(), [
        MarkupHeading,
        MarkupParagraph,
        MarkupHeading,
        MarkupParagraph,
      ]);
      expect((blocks[0] as MarkupHeading).level, 2);
      expect((blocks[2] as MarkupHeading).level, 3);

      // No marker anywhere survives into what a reader sees.
      for (final block in blocks) {
        expect(block.plainText, isNot(contains('##')));
        expect(block.plainText, isNot(contains('**')));
      }
    });
  });

  group('Markup.plainText', () {
    test('strips every marker for places that cannot show style', () {
      expect(Markup.plainText('## शीर्षक\n\n**मोटा** पाठ'), 'शीर्षक मोटा पाठ');
    });
  });

  group('Markup.isHeadingOnly', () {
    test('tells a title apart from the prose under it', () {
      expect(Markup.isHeadingOnly('## राधाकृष्ण ठाकुरबाड़ी'), isTrue);
      expect(Markup.isHeadingOnly('मंदिर की स्थापना 1975 में हुई।'), isFalse);
      expect(Markup.isHeadingOnly(''), isFalse);
    });
  });
}
