import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two languages, held to each other.
///
/// Hindi is the source language and English is the secondary one, and the app
/// is generated from these two files. Nothing in the build fails when they
/// disagree: a key present in one and missing from the other is a compile
/// error only if a screen happens to use it, and a placeholder named
/// differently in the two files produces the *wrong sentence* at run time in
/// one language, silently.
///
/// So the files are compared directly, as data.
Map<String, Object?> _arb(String name) {
  final file = File('lib/l10n/$name');
  expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Set<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

/// `{count}` and `{year}` out of "सभी {count} तस्वीरें देखें".
Set<String> _placeholders(String value) =>
    RegExp(r'\{(\w+)[,}]')
        .allMatches(value)
        .map((match) => match.group(1)!)
        .toSet();

void main() {
  late final Map<String, Object?> hi;
  late final Map<String, Object?> en;

  setUpAll(() {
    hi = _arb('app_hi.arb');
    en = _arb('app_en.arb');
  });

  test('every Hindi string has an English one, and the reverse', () {
    final hiKeys = _messageKeys(hi);
    final enKeys = _messageKeys(en);

    expect(
      hiKeys.difference(enKeys),
      isEmpty,
      reason: 'these exist in Hindi and not in English',
    );
    expect(
      enKeys.difference(hiKeys),
      isEmpty,
      reason:
          'these exist in English and not in Hindi — which is worse: '
          'Hindi is the language the fallback falls back *to*',
    );
  });

  /// A `{name}` in one file and `{userName}` in the other compiles, generates
  /// two different method signatures, and produces a sentence with a literal
  /// brace in it for whichever language is wrong.
  test('a message takes the same placeholders in both languages', () {
    final mismatched = <String>[];

    for (final key in _messageKeys(hi)) {
      final hindi = hi[key];
      final english = en[key];
      if (hindi is! String || english is! String) continue;

      if (!setEquals(_placeholders(hindi), _placeholders(english))) {
        mismatched.add(
          '$key: hi${_placeholders(hindi)} vs en${_placeholders(english)}',
        );
      }
    }

    expect(mismatched, isEmpty);
  });

  test('no string is empty in either language', () {
    for (final arb in [hi, en]) {
      for (final key in _messageKeys(arb)) {
        final value = arb[key];
        expect(
          value is String && value.trim().isNotEmpty,
          isTrue,
          reason: '$key is empty',
        );
      }
    }
  });

  /// The one that catches a forgotten translation: a Hindi entry still holding
  /// the English text.
  ///
  /// Not every identical pair is a mistake — a URL, a number, a proper noun and
  /// the language names themselves are deliberately the same in both — so the
  /// known ones are listed rather than the rule being weakened.
  test('no Hindi string is still the English one', () {
    const deliberatelyIdentical = {
      // Shown in their own script in both languages, on purpose: somebody
      // looking for English needs to see the word "English".
      'languageHindi',
      'languageEnglish',
      'appTitle',

      // Acronyms and brand names. "UPI" is UPI in Hindi too, and transliterating
      // "IFSC" would make a bank form unusable.
      'fieldUpiId',
      'fieldIfsc',
      'donateQrLabel',
      'modeUpi',
      'announcementChannelWhatsapp',
      'reportExportCsv',
      'reportExportXlsx',

      // A date format and a two-letter marker, both read as symbols rather
      // than as words.
      'dateHint',
      'valueNotAvailable',

      // Placeholders and punctuation only — there is nothing in it to translate.
      'mediaFileSelected',
    };

    final untranslated = <String>[];

    for (final key in _messageKeys(hi)) {
      if (deliberatelyIdentical.contains(key)) continue;

      final hindi = hi[key];
      final english = en[key];
      if (hindi is! String || english is! String) continue;

      // A string with no Devanagari in it at all, that is also identical to the
      // English, has not been translated. Numerals, symbols and placeholders
      // are excluded by requiring a letter.
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(hindi);
      final hasDevanagari = RegExp(r'[ऀ-ॿ]').hasMatch(hindi);

      if (hindi == english && hasLetters && !hasDevanagari) {
        untranslated.add(key);
      }
    }

    expect(untranslated, isEmpty, reason: 'still in English in the Hindi file');
  });
}
