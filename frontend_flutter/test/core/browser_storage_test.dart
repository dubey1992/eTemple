import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing this client holds is written to browser storage.
///
/// The specification asks for "no sensitive tokens in insecure browser
/// storage". The answer here is stronger than a rule about which values are
/// safe to keep: **nothing is kept at all**. The session is an HttpOnly cookie
/// the browser attaches and JavaScript cannot read, so there is no token in the
/// client to store in the first place, and every other piece of state lives in
/// memory for the life of the tab.
///
/// A source sweep rather than a widget test, for the same reason the
/// `LinkOpener` fix needed one: the failure mode is a call site somebody adds
/// later, and no rendered screen can show you a `localStorage.setItem` that
/// runs on one code path in one browser.
void main() {
  /// Every way a Dart web app can reach persistent per-visitor storage.
  ///
  /// `shared_preferences` is on the list because on the web it *is*
  /// `localStorage` — a name that hides where the data goes is exactly the kind
  /// that gets used without thinking.
  const forbidden = <String, String>{
    'localStorage': 'browser local storage',
    'sessionStorage': 'browser session storage',
    'SharedPreferences': 'shared_preferences, which is localStorage on the web',
    'indexedDB': 'IndexedDB',
  };

  /// The one directory allowed to persist anything, and why it is a directory
  /// rather than a file: the web implementation, its no-op counterpart, the
  /// conditional export and the provider only make sense together.
  const permitted = 'lib/core/storage/';

  test('only the credential store reaches for persistent browser storage', () {
    final offenders = <String>[];

    for (final file in _dartFilesUnder('lib')) {
      final path = file.path.replaceAll('\\', '/');
      if (path.contains(permitted)) continue;

      final source = file.readAsStringSync();

      for (final entry in forbidden.entries) {
        if (source.contains(entry.key)) {
          offenders.add('${file.path}: ${entry.value}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Only lib/core/storage/ may persist anything in the browser, and it '
          'holds one thing: the sign-in details the committee asked to have '
          'remembered. Nothing else may be written - not a session value, not '
          'a token, and nothing whatever about a donor. A second call site is '
          'how a narrow, deliberate exception becomes a habit.\n'
          '${offenders.join('\n')}',
    );
  });

  test('the exception has not quietly grown', () {
    final files =
        _dartFilesUnder('lib')
            .map((f) => f.path.replaceAll('\\', '/'))
            .where((p) => p.contains(permitted))
            .map((p) => p.split('/').last)
            .toList()
          ..sort();

    // Anything new in here persists something new, and should be argued for
    // rather than added.
    expect(files, [
      'credential_store.dart',
      'credential_store_io.dart',
      'credential_store_provider.dart',
      'credential_store_web.dart',
      'saved_credentials.dart',
    ]);
  });

  test('nothing but the sign-in form reads the stored credentials', () {
    // A stored password is a convenience for two text fields. If it is read
    // anywhere else, something has begun treating it as authentication.
    final readers = <String>[];

    for (final file in _dartFilesUnder('lib')) {
      final path = file.path.replaceAll('\\', '/');
      if (path.contains(permitted)) continue;
      if (!file.readAsStringSync().contains('credentialStoreProvider')) {
        continue;
      }
      readers.add(path.split('/').last);
    }

    expect(readers, ['login_screen.dart']);
  });

  /// Cookies are read, never written.
  ///
  /// Reading is necessary and safe: Laravel deliberately exposes `XSRF-TOKEN`
  /// to script so the client can echo it back as a header. Writing one from
  /// script would mean the client had invented a session value of its own,
  /// which is the thing that must not happen.
  test('no Dart source writes a cookie', () {
    final offenders = <String>[];

    for (final file in _dartFilesUnder('lib')) {
      // `document.cookie = …`, allowing for whitespace, but not `==`.
      if (RegExp(r'document\.cookie\s*=[^=]')
          .hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  /// The one cookie the client reads, and the only one it may.
  test('the only cookie read is the CSRF token', () {
    final source = _read('lib/core/api/api_client.dart');

    final reads = RegExp(r"readCookie\('([^']+)'\)")
        .allMatches(source)
        .map((match) => match.group(1))
        .toSet();

    expect(reads, {'XSRF-TOKEN'});
  });

  /// The session travels as a cookie the browser attaches, not as a token the
  /// client holds.
  ///
  /// If this ever became a bearer token read from somewhere, the sweep above
  /// would stop being enough — and this is the line that would have changed.
  test('the API client authenticates with the cookie, not with a token', () {
    final web = _read('lib/core/api/browser/browser_support_web.dart');

    expect(web.contains('withCredentials = true'), isTrue);

    for (final path in const [
      'lib/core/api/api_client.dart',
      'lib/core/api/browser/browser_support_web.dart',
    ]) {
      expect(
        RegExp(r'Authorization').hasMatch(_read(path)),
        isFalse,
        reason:
            '$path: a bearer token would have to be stored somewhere '
            'a script can read',
      );
    }
  });
}

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

Iterable<File> _dartFilesUnder(String directory) sync* {
  for (final entity in Directory(directory).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}
