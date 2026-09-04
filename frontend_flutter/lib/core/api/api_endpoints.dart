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

  static const String resetPassword = '/auth/reset-password';

  /// Served from the application root, not from under `/api`.
  static const String csrfCookie = '/sanctum/csrf-cookie';
}
