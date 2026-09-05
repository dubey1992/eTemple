/// Stable error codes shared with the Laravel API.
///
/// Mirrors `app/Support/ApiErrorCode.php`. The wire values must stay identical
/// on both sides; the extra client-only values cover failures that never reach
/// the server (no network, timeout, unparseable payload).
enum ErrorCode {
  // --- Mirrored from the backend -------------------------------------------
  validationFailed('VALIDATION_FAILED'),
  unauthenticated('UNAUTHENTICATED'),
  invalidCredentials('INVALID_CREDENTIALS'),
  accountInactive('ACCOUNT_INACTIVE'),
  accountBlocked('ACCOUNT_BLOCKED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  methodNotAllowed('METHOD_NOT_ALLOWED'),
  tooManyRequests('TOO_MANY_REQUESTS'),
  csrfTokenMismatch('CSRF_TOKEN_MISMATCH'),

  /// A media file cannot be deleted because something still points at it
  /// (Phase 5 deletion guard). Distinct from a validation failure: the request
  /// was well formed, the state of the site refuses it — and the UI answers it
  /// differently, by listing what is in the way.
  mediaInUse('MEDIA_IN_USE'),

  /// A donation cannot be changed, confirmed or reversed because of the state
  /// it is already in (Phase 6). Like [mediaInUse] this is a fact about the
  /// record rather than a fault in the request, and the UI says so.
  donationLocked('DONATION_LOCKED'),

  /// The contact form's ticket was missing, forged, spent or stale (Phase 7).
  /// The screen's move is to fetch a fresh form and let the visitor send again
  /// without retyping anything.
  enquiryFormExpired('ENQUIRY_FORM_EXPIRED'),

  /// This address must now answer a question before the form is accepted
  /// (Phase 7). Recoverable by fetching a fresh form, which carries one.
  enquiryChallengeRequired('ENQUIRY_CHALLENGE_REQUIRED'),

  /// An announcement has already been sent, and a message cannot be unsent
  /// (Phase 8). A fact about the notice rather than a fault in the request.
  announcementAlreadySent('ANNOUNCEMENT_ALREADY_SENT'),

  /// Sending was asked for on an announcement that is not published (Phase 8).
  announcementNotPublished('ANNOUNCEMENT_NOT_PUBLISHED'),

  serverError('SERVER_ERROR'),

  // --- Client-only ----------------------------------------------------------
  network('NETWORK_UNAVAILABLE'),
  timeout('TIMEOUT'),
  cancelled('CANCELLED'),
  malformedResponse('MALFORMED_RESPONSE'),
  unknown('UNKNOWN');

  const ErrorCode(this.wireValue);

  final String wireValue;

  static ErrorCode fromWire(String? value) {
    if (value == null) return ErrorCode.unknown;
    for (final code in ErrorCode.values) {
      if (code.wireValue == value) return code;
    }
    return ErrorCode.unknown;
  }

  /// True when the user should be sent back to the sign-in screen.
  bool get requiresReauthentication =>
      this == ErrorCode.unauthenticated ||
      this == ErrorCode.accountInactive ||
      this == ErrorCode.accountBlocked;
}
