import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/error_code.dart';

/// `ErrorCode` really does mirror `ApiErrorCode`.
///
/// The PHP catalogue says of itself: *"These strings are part of the public API
/// contract and are mirrored by the Flutter client. Never rename a code without
/// changing the client in the same release."* Nothing enforced that, and Phase 6
/// duly shipped `DONATION_LOCKED` on the server with no client-side match — so
/// a treasurer who edited a receipted donation was told "something went wrong"
/// instead of being told a receipt had been issued. The translated message for
/// it existed the whole time; only the enum entry was missing, and no test could
/// notice a gap between two languages.
///
/// This is that test. It reads the catalogue across the repository, which is the
/// only place the two halves of the contract can be compared at all.
void main() {
  test('every backend error code has a client mirror', () {
    final source = File('../backend_laravel/app/Support/ApiErrorCode.php');

    if (!source.existsSync()) {
      // A frontend-only checkout is a legitimate way to work; the check simply
      // cannot run there, and skipping is honest where a false pass is not.
      markTestSkipped('backend_laravel is not checked out beside this package');
      return;
    }

    final backendCodes = RegExp(r"const\s+\w+\s*=\s*'([A-Z_]+)'")
        .allMatches(source.readAsStringSync())
        .map((match) => match.group(1)!)
        .toSet();

    expect(
      backendCodes,
      isNotEmpty,
      reason: 'the catalogue was found but no codes were read out of it',
    );

    final clientCodes = ErrorCode.values.map((code) => code.wireValue).toSet();

    expect(
      backendCodes.difference(clientCodes),
      isEmpty,
      reason:
          'these API error codes have no ErrorCode entry, so the client will '
          'show the generic "something went wrong" instead of the message '
          'written for them',
    );
  });

  test('every mirrored code keeps its wire value', () {
    // Spot-checks of the values other layers hard-code, so a rename shows up
    // here rather than as a silently generic message in production.
    expect(ErrorCode.fromWire('DONATION_LOCKED'), ErrorCode.donationLocked);
    expect(
      ErrorCode.fromWire('ENQUIRY_FORM_EXPIRED'),
      ErrorCode.enquiryFormExpired,
    );
    expect(
      ErrorCode.fromWire('ENQUIRY_CHALLENGE_REQUIRED'),
      ErrorCode.enquiryChallengeRequired,
    );
    expect(ErrorCode.fromWire('SOMETHING_NEW'), ErrorCode.unknown);
  });
}
