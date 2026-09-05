import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/files/link_opener.dart';

/// Which opener each kind of link uses.
///
/// This exists because getting it wrong is invisible: the tab opens, the URL is
/// right, and the API answers 401 because it never saw where the request came
/// from.
///
/// Sanctum decides a request is stateful — and therefore carries the session —
/// by matching the `Referer` **or** the `Origin` against its configured
/// domains. A top-level navigation started by `window.open` sends no `Origin`,
/// so `noreferrer` leaves the request with neither and the caller is anonymous.
///
/// The receipt (Phase 6), the bill (Phase 9) and the three exports (Phase 10)
/// are all our own authenticated endpoints and must use [LinkOpener.openOwn].
/// The video darshan link (Phase 5) is a third party and must not.
void main() {
  test('both openers exist, so a call site has to choose', () {
    const opener = LinkOpener();

    // On the Dart VM both are no-ops. What matters here is that the API has
    // two doors; which one each screen walks through is asserted below.
    expect(opener.open('https://example.test'), isFalse);
    expect(opener.openOwn('https://example.test'), isFalse);
  });

  /// A source sweep rather than a widget test: the failure mode is a call site
  /// reaching for the wrong method, which is a property of the code rather than
  /// of any one rendered screen — and a widget test cannot see a missing HTTP
  /// header anyway.
  test('our own authenticated endpoints are opened with openOwn', () {
    for (final path in const [
      'lib/features/reports/presentation/admin_report_screen.dart',
      'lib/features/accounts/presentation/admin_transaction_editor_screen.dart',
      'lib/features/donations/presentation/admin_donation_editor_screen.dart',
    ]) {
      final source = _read(path);

      expect(
        source.contains('.openOwn('),
        isTrue,
        reason: '$path opens one of our own endpoints and must use openOwn',
      );
      // `(?<!Own)` so `.openOwn(` does not match as `.open(`.
      expect(
        RegExp(r'(?<!Own)\.open\(').hasMatch(source),
        isFalse,
        reason: '$path must not strip the Referer from its own API',
      );
    }
  });

  test('a third-party link keeps noreferrer', () {
    final source = _read(
      'lib/features/media/presentation/widgets/media_lightbox.dart',
    );

    // The video darshan link goes to YouTube: it needs no session, and should
    // carry no referrer.
    expect(source.contains('.openOwn('), isFalse);
    expect(RegExp(r'\.open\(').hasMatch(source), isTrue);
  });

  test('the web opener strips the referrer only for third parties', () {
    // Read rather than executed: `dart:js_interop` will not load on the VM, and
    // the two `window.open` calls are the whole behaviour under test.
    final source = _read('lib/core/files/link_opener_web.dart');

    expect(source.contains("'noopener,noreferrer'"), isTrue);
    expect(source.contains("'noopener'"), isTrue);
  });
}

String _read(String relativePath) {
  final file = File(relativePath);
  expect(file.existsSync(), isTrue, reason: '$relativePath is missing');
  return file.readAsStringSync();
}
