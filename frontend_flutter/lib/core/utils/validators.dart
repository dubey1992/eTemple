/// Result of a field validation, independent of any language.
///
/// Validators return one of these instead of a message so the rules stay pure,
/// unit-testable and free of localization concerns; the presentation layer turns
/// the value into Hindi or English text.
enum ValidationError { required, invalidEmail, passwordTooShort }

/// Client-side input rules.
///
/// These mirror the Laravel Form Requests so a visitor gets immediate feedback,
/// but they are a convenience only — the server validates every write request
/// independently and remains authoritative.
class Validators {
  const Validators._();

  /// Minimum password length; must match `LoginRequest` on the backend.
  static const int passwordMinLength = 8;

  // Deliberately permissive: rejects the obviously wrong (no @, no dot, spaces)
  // without inventing rules the server does not apply.
  static final RegExp _email = RegExp(
    r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?"
    r'(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$',
  );

  static ValidationError? notEmpty(String? value) {
    return (value == null || value.trim().isEmpty)
        ? ValidationError.required
        : null;
  }

  static ValidationError? email(String? value) {
    final missing = notEmpty(value);
    if (missing != null) return missing;

    final candidate = value!.trim();
    if (candidate.length > 191 || !_email.hasMatch(candidate)) {
      return ValidationError.invalidEmail;
    }
    return null;
  }

  static ValidationError? password(String? value) {
    final missing = notEmpty(value);
    if (missing != null) return missing;

    // Not trimmed: a leading or trailing space is a legitimate password
    // character and must count towards the length.
    return value!.length < passwordMinLength
        ? ValidationError.passwordTooShort
        : null;
  }
}
