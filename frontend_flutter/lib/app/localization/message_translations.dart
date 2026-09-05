import '../../core/errors/app_exception.dart';
import '../../core/errors/error_code.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';

/// Turns language-free domain results into localized, user-safe text.
///
/// Keeping the mapping here means error handling stays testable without a
/// widget tree, and no server message or exception detail is ever rendered
/// directly to a visitor.
extension AppExceptionMessage on AppException {
  String localizedMessage(AppLocalizations l10n) => switch (code) {
    ErrorCode.network => l10n.errorNetwork,
    ErrorCode.timeout => l10n.errorTimeout,
    ErrorCode.invalidCredentials => l10n.errorInvalidCredentials,
    ErrorCode.accountInactive => l10n.errorAccountInactive,
    ErrorCode.accountBlocked => l10n.errorAccountBlocked,
    ErrorCode.unauthenticated => l10n.errorUnauthenticated,
    ErrorCode.forbidden => l10n.errorForbidden,
    ErrorCode.notFound => l10n.errorNotFound,
    ErrorCode.methodNotAllowed => l10n.errorUnknown,
    ErrorCode.validationFailed => l10n.errorValidation,
    ErrorCode.tooManyRequests => l10n.errorTooManyRequests,
    ErrorCode.csrfTokenMismatch => l10n.errorSessionExpired,
    ErrorCode.mediaInUse => l10n.mediaInUseTitle,
    ErrorCode.donationLocked => l10n.errorDonationLocked,
    ErrorCode.enquiryFormExpired => l10n.errorEnquiryFormExpired,
    ErrorCode.enquiryChallengeRequired => l10n.errorEnquiryChallengeRequired,
    ErrorCode.announcementAlreadySent => l10n.errorAnnouncementAlreadySent,
    ErrorCode.announcementNotPublished => l10n.errorAnnouncementNotPublished,
    ErrorCode.transactionLocked => l10n.errorTransactionLocked,
    ErrorCode.accountsNotPublished => l10n.errorAccountsNotPublished,
    ErrorCode.serverError => l10n.errorServer,
    ErrorCode.cancelled => l10n.errorUnknown,
    ErrorCode.malformedResponse => l10n.errorServer,
    ErrorCode.unknown => l10n.errorUnknown,
  };
}

extension ValidationErrorMessage on ValidationError {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    ValidationError.required => l10n.validationRequired,
    ValidationError.invalidEmail => l10n.validationEmailInvalid,
    ValidationError.passwordTooShort => l10n.validationPasswordTooShort(
      Validators.passwordMinLength,
    ),
  };
}
