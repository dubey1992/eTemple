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
