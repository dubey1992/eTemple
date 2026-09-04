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
  static const String adminRolePermissions = 'admin-role-permissions';
  static const String resetPassword = 'reset-password';
}
