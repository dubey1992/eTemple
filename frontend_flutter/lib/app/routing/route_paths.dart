/// Every route path and name in the application.
///
/// Public and admin routes are separated by prefix so the guard, the navigation
/// and later phases' permission checks all key off the same strings.
class RoutePaths {
  const RoutePaths._();

  // --- Public ---------------------------------------------------------------
  static const String home = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  /// The committee page. Declared before the catch-all slug route so it is
  /// not mistaken for a CMS page.
  static const String committee = '/committee';

  /// The public calendar. Declared before the catch-all slug route.
  static const String events = '/events';

  static const String eventDetailPattern = '/events/:id';

  /// The public donation page. Declared before the catch-all slug route.
  static const String donate = '/donate';

  /// The public gallery. Declared before the catch-all slug route.
  static const String gallery = '/gallery';

  /// The contact page: the address, and the form. Declared before the
  /// catch-all slug route.
  static const String contact = '/contact';

  /// What the temple did with the money. Aggregates only — there is no route
  /// to an individual entry here, because there is no endpoint behind one.
  /// Declared before the catch-all slug route.
  static const String transparency = '/transparency';

  /// [album] is an album slug, so a link to one festival's photographs is
  /// shareable.
  static String galleryAlbum(String album) => '/gallery?album=$album';

  /// [on] names one occurrence of a repeating event, so a shared link to "the
  /// aarti on the 12th" still opens on the 12th.
  static String eventDetail(int id, {String? on}) =>
      on == null ? '/events/$id' : '/events/$id?on=$on';

  /// A CMS page lives at its own slug, so /about is a clean, shareable URL.
  /// Declared last in the router so it cannot shadow the routes above.
  static const String pagePattern = '/:slug';

  static String page(String slug) => '/$slug';

  // --- Admin (protected) ----------------------------------------------------
  static const String admin = '/admin';
  static const String adminPages = '/admin/pages';

  static String adminPageEditor(int id) => '/admin/pages/$id';

  static const String adminSiteSettings = '/admin/site-settings';

  static const String adminUsers = '/admin/users';
  static const String adminUserNew = '/admin/users/new';

  static String adminUserEditor(int id) => '/admin/users/$id';

  static const String adminRoles = '/admin/roles';

  static const String adminTempleProfile = '/admin/temple-profile';

  static const String adminCommittee = '/admin/committee';
  static const String adminCommitteeNew = '/admin/committee/new';

  static String adminCommitteeMember(int id) => '/admin/committee/$id';

  static const String adminEvents = '/admin/events';
  static const String adminEventNew = '/admin/events/new';

  static String adminEventEditor(int id) => '/admin/events/$id';

  static const String adminMedia = '/admin/media';
  static const String adminMediaNew = '/admin/media/new';

  static String adminMediaEditor(int id) => '/admin/media/$id';

  static const String adminAlbums = '/admin/albums';
  static const String adminAlbumNew = '/admin/albums/new';

  static String adminAlbumEditor(int id) => '/admin/albums/$id';

  static const String adminDonations = '/admin/donations';
  static const String adminDonationNew = '/admin/donations/new';

  static String adminDonationDetail(int id) => '/admin/donations/$id';

  static const String adminDonationSettings = '/admin/donation-settings';

  static const String adminAnnouncements = '/admin/announcements';
  static const String adminAnnouncementNew = '/admin/announcements/new';

  static String adminAnnouncementEditor(int id) => '/admin/announcements/$id';

  static const String adminAccounts = '/admin/accounts';
  static const String adminAccountNew = '/admin/accounts/new';

  static String adminAccountDetail(int id) => '/admin/accounts/$id';

  static const String adminAccountingCategories =
      '/admin/accounting-categories';

  static const String adminAccountingSettings = '/admin/accounting-settings';

  static const String adminEnquiries = '/admin/enquiries';

  static String adminEnquiryDetail(int id) => '/admin/enquiries/$id';

  static String adminRolePermissions(int id) => '/admin/roles/$id';

  // --- Public (completes the Phase 0 password-reset flow) -------------------
  static const String resetPassword = '/reset-password';

  /// True for any route inside the protected admin group.
  static bool isAdmin(String location) =>
      location == admin || location.startsWith('$admin/');
}

class RouteNames {
  const RouteNames._();

  static const String home = 'home';
  static const String login = 'login';
  static const String forgotPassword = 'forgot-password';
  static const String adminOverview = 'admin-overview';
  static const String adminPages = 'admin-pages';
  static const String adminPageEditor = 'admin-page-editor';
  static const String page = 'cms-page';
  static const String adminSiteSettings = 'admin-site-settings';
  static const String adminUsers = 'admin-users';
  static const String adminUserEditor = 'admin-user-editor';
  static const String adminRoles = 'admin-roles';
  static const String committee = 'committee';
  static const String adminTempleProfile = 'admin-temple-profile';
  static const String adminCommittee = 'admin-committee';
  static const String adminCommitteeMember = 'admin-committee-member';
  static const String events = 'events';
  static const String eventDetail = 'event-detail';
  static const String adminEvents = 'admin-events';
  static const String adminEventEditor = 'admin-event-editor';
  static const String gallery = 'gallery';
  static const String adminMedia = 'admin-media';
  static const String adminMediaEditor = 'admin-media-editor';
  static const String adminAlbums = 'admin-albums';
  static const String adminAlbumEditor = 'admin-album-editor';
  static const String donate = 'donate';
  static const String contact = 'contact';
  static const String transparency = 'transparency';
  static const String adminAccounts = 'admin-accounts';
  static const String adminAccountEditor = 'admin-account-editor';
  static const String adminAccountingCategories = 'admin-accounting-categories';
  static const String adminAccountingSettings = 'admin-accounting-settings';
  static const String adminAnnouncements = 'admin-announcements';
  static const String adminAnnouncementEditor = 'admin-announcement-editor';
  static const String adminEnquiries = 'admin-enquiries';
  static const String adminEnquiryDetail = 'admin-enquiry-detail';
  static const String adminDonations = 'admin-donations';
  static const String adminDonationDetail = 'admin-donation-detail';
  static const String adminDonationSettings = 'admin-donation-settings';
  static const String adminRolePermissions = 'admin-role-permissions';
  static const String resetPassword = 'reset-password';
}
