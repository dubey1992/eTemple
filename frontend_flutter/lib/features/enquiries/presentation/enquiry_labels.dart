import '../../../l10n/app_localizations.dart';
import '../domain/enquiry.dart';

/// The words for the codes the API sends.
///
/// The server sends a bilingual label with every category so that a client
/// which has not been taught a newly added code still shows words. That is the
/// fallback, not the default: when this client *does* know the code it uses its
/// own ARB translation, because the visitor asked for one language and
/// "सामान्य जानकारी / General enquiry" is two.
class EnquiryLabels {
  const EnquiryLabels._();

  static String category(
    AppLocalizations l10n,
    String code, {
    String? fallback,
  }) => switch (code) {
    EnquiryCategories.general => l10n.enquiryCategoryGeneral,
    EnquiryCategories.pujaBooking => l10n.enquiryCategoryPujaBooking,
    EnquiryCategories.donation => l10n.enquiryCategoryDonation,
    EnquiryCategories.event => l10n.enquiryCategoryEvent,
    EnquiryCategories.volunteer => l10n.enquiryCategoryVolunteer,
    EnquiryCategories.suggestion => l10n.enquiryCategorySuggestion,
    EnquiryCategories.complaint => l10n.enquiryCategoryComplaint,
    EnquiryCategories.other => l10n.enquiryCategoryOther,
    // A code from a newer server than this bundle: the server's own label,
    // and only the code itself if even that is missing.
    _ => (fallback == null || fallback.isEmpty) ? code : fallback,
  };

  static String status(AppLocalizations l10n, String code) => switch (code) {
    EnquiryStatuses.isNew => l10n.enquiryStatusNew,
    EnquiryStatuses.inProgress => l10n.enquiryStatusInProgress,
    EnquiryStatuses.resolved => l10n.enquiryStatusResolved,
    EnquiryStatuses.spam => l10n.enquiryStatusSpam,
    _ => code,
  };

  /// The language a devotee asked to be answered in.
  static String language(AppLocalizations l10n, String code) =>
      code == 'en' ? l10n.languageEnglish : l10n.languageHindi;
}
