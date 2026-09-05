/// Every path the client knows about, relative to the configured API base URL.
///
/// Keeping them in one place makes the Flutter side of the API contract greppable
/// and keeps route strings out of widgets.
class ApiEndpoints {
  const ApiEndpoints._();

  // Public
  static const String health = '/health';

  // Authentication (Phase 0)
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';

  // Public website content (Phase 1)
  static const String publicSiteSettings = '/public/site-settings';

  static String publicPage(String slug) => '/public/pages/$slug';

  // Temple identity and committee (Phase 3)
  static const String publicTempleProfile = '/public/temple-profile';

  static const String publicCommittee = '/public/committee';

  // Puja, events and the calendar (Phase 4)
  static const String publicEvents = '/public/events';

  static String publicEvent(int id) => '/public/events/$id';

  // Gallery and video darshan (Phase 5)
  static const String publicMedia = '/public/media';

  static String publicMediaItem(int id) => '/public/media/$id';

  static const String publicAlbums = '/public/albums';

  // Protected admin surface (Phase 0 foundation)
  static const String adminPing = '/admin/ping';

  // Content management (Phase 1)
  static const String adminPages = '/admin/pages';

  static String adminPage(int id) => '/admin/pages/$id';

  static const String adminSiteSettings = '/admin/site-settings';

  // Committee accounts, roles and the permission matrix (Phase 2)
  static const String adminUsers = '/admin/users';

  static String adminUser(int id) => '/admin/users/$id';

  static String adminUserLoginHistory(int id) =>
      '/admin/users/$id/login-history';

  static String adminUserPasswordReset(int id) =>
      '/admin/users/$id/send-password-reset';

  static const String adminRoles = '/admin/roles';

  static const String adminPermissions = '/admin/permissions';

  static String adminRolePermissions(int id) => '/admin/roles/$id/permissions';

  // Temple profile and committee management (Phase 3)
  static const String adminTempleProfile = '/admin/temple-profile';

  static const String adminCommitteeMembers = '/admin/committee-members';

  static String adminCommitteeMember(int id) => '/admin/committee-members/$id';

  static const String adminEvents = '/admin/events';

  static String adminEvent(int id) => '/admin/events/$id';

  // Media library (Phase 5)
  static const String adminMedia = '/admin/media';

  static String adminMediaItem(int id) => '/admin/media/$id';

  static String adminMediaReferences(int id) => '/admin/media/$id/references';

  static const String adminMediaVideo = '/admin/media/video';

  static const String adminMediaReorder = '/admin/media/reorder';

  static const String adminAlbums = '/admin/albums';

  static String adminAlbum(int id) => '/admin/albums/$id';

  // Donations and receipts (Phase 6)
  static const String publicDonationSettings = '/public/donation-settings';

  static const String adminDonations = '/admin/donations';

  static String adminDonation(int id) => '/admin/donations/$id';

  static String adminDonationConfirm(int id) => '/admin/donations/$id/confirm';

  static String adminDonationReverse(int id) => '/admin/donations/$id/reverse';

  /// A printable HTML document rather than JSON, opened in a new tab — see
  /// `ReceiptRenderer` for why the browser, not the server, makes the PDF.
  static String adminDonationReceipt(int id) => '/admin/donations/$id/receipt';

  static const String adminDonationSettings = '/admin/donation-settings';

  // Devotee contact and enquiries (Phase 7)

  /// The ticket the contact form is submitted with, and the question that comes
  /// with it once an address has sent enough messages.
  static const String publicEnquiryForm = '/public/enquiry-form';

  static const String publicEnquiries = '/public/enquiries';

  /// There is no public *read* of an enquiry, at any status, by design — so
  /// there is no constant here for one either (PHASE_7_PLAN assumption N1).
  static const String adminEnquiries = '/admin/enquiries';

  static const String adminEnquirySummary = '/admin/enquiries/summary';

  static String adminEnquiry(int id) => '/admin/enquiries/$id';

  static String adminEnquiryStatus(int id) => '/admin/enquiries/$id/status';

  static const String resetPassword = '/auth/reset-password';

  /// Served from the application root, not from under `/api`.
  static const String csrfCookie = '/sanctum/csrf-cookie';
}
