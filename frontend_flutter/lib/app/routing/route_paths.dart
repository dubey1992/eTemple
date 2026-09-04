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

  /// A CMS page lives at its own slug, so /about is a clean, shareable URL.
  /// Declared last in the router so it cannot shadow the routes above.
  static const String pagePattern = '/:slug';

  static String page(String slug) => '/$slug';

  // --- Admin (protected) ----------------------------------------------------
  static const String admin = '/admin';
  static const String adminPages = '/admin/pages';

  static String adminPageEditor(int id) => '/admin/pages/$id';

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
}
