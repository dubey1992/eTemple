import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/shell/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_role_permissions_screen.dart';
import '../../features/admin/presentation/admin_roles_screen.dart';
import '../../features/admin/presentation/admin_user_editor_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/content/presentation/admin_page_editor_screen.dart';
import '../../features/content/presentation/admin_site_settings_screen.dart';
import '../../features/content/presentation/admin_pages_screen.dart';
import '../../features/content/presentation/home_screen.dart';
import '../../features/content/presentation/page_screen.dart';
import '../../features/events/presentation/admin_event_editor_screen.dart';
import '../../features/events/presentation/admin_events_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/donations/presentation/admin_donation_editor_screen.dart';
import '../../features/donations/presentation/admin_donation_settings_screen.dart';
import '../../features/donations/presentation/admin_donations_screen.dart';
import '../../features/donations/presentation/donate_screen.dart';
import '../../features/announcements/presentation/admin_announcement_editor_screen.dart';
import '../../features/announcements/presentation/admin_announcements_screen.dart';
import '../../features/enquiries/presentation/admin_enquiries_screen.dart';
import '../../features/enquiries/presentation/admin_enquiry_detail_screen.dart';
import '../../features/enquiries/presentation/contact_screen.dart';
import '../../features/accounts/presentation/admin_accounting_categories_screen.dart';
import '../../features/accounts/presentation/admin_accounting_settings_screen.dart';
import '../../features/accounts/presentation/admin_accounts_screen.dart';
import '../../features/accounts/presentation/admin_transaction_editor_screen.dart';
import '../../features/accounts/presentation/transparency_screen.dart';
import '../../features/reports/presentation/admin_report_screen.dart';
import '../../features/reports/presentation/admin_reports_screen.dart';
import '../../features/media/presentation/admin_album_editor_screen.dart';
import '../../features/media/presentation/admin_albums_screen.dart';
import '../../features/media/presentation/admin_media_editor_screen.dart';
import '../../features/media/presentation/admin_media_screen.dart';
import '../../features/media/presentation/gallery_screen.dart';
import '../../features/shell/presentation/not_found_screen.dart';
import '../../features/shell/presentation/public_shell.dart';
import '../../features/temple/presentation/admin_committee_member_screen.dart';
import '../../features/temple/presentation/admin_committee_screen.dart';
import '../../features/temple/presentation/admin_temple_profile_screen.dart';
import '../../features/temple/presentation/committee_screen.dart';
import 'route_paths.dart';

/// Bridges the Riverpod session state to go_router's [Listenable] API so the
/// guard re-evaluates the moment a sign-in or sign-out changes the session.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AsyncValue<AuthUser?>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthUser?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// The application router.
///
/// Public and admin routes are separate branches with separate shells. The
/// redirect below is a convenience for the visitor — every protected API call is
/// independently authorized on the server, so bypassing this guard gains nothing.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final session = ref.read(authControllerProvider);

      // The session is still being restored (page load or hard refresh). Hold
      // the current URL rather than bouncing a signed-in user to /login.
      if (session.isLoading) return null;

      final user = session.value;
      final isSignedIn = user != null && user.isActive;
      final location = state.matchedLocation;

      if (RoutePaths.isAdmin(location) && !isSignedIn) {
        return RoutePaths.login;
      }

      // A reset link is deliberately not bounced: someone may be signed in on
      // one device and resetting because another was compromised.
      if (isSignedIn &&
          (location == RoutePaths.login ||
              location == RoutePaths.forgotPassword)) {
        return RoutePaths.admin;
      }

      return null;
    },
    routes: [
      // --- Public branch ------------------------------------------------
      ShellRoute(
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            // Declared here rather than left to the catch-all slug route, so
            // /committee is never mistaken for a CMS page.
            path: RoutePaths.committee,
            name: RouteNames.committee,
            builder: (context, state) => const CommitteeScreen(),
          ),
          GoRoute(
            path: RoutePaths.events,
            name: RouteNames.events,
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            // Declared here rather than left to the catch-all slug route, so
            // /donate is never mistaken for a CMS page.
            path: RoutePaths.donate,
            name: RouteNames.donate,
            builder: (context, state) => const DonateScreen(),
          ),
          GoRoute(
            // Declared here rather than left to the catch-all slug route, so
            // /contact is never mistaken for a CMS page.
            path: RoutePaths.contact,
            name: RouteNames.contact,
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            // Declared here rather than left to the catch-all slug route, so
            // /transparency is never mistaken for a CMS page.
            path: RoutePaths.transparency,
            name: RouteNames.transparency,
            builder: (context, state) => const TransparencyScreen(),
          ),
          GoRoute(
            // Declared here rather than left to the catch-all slug route, so
            // /gallery is never mistaken for a CMS page.
            path: RoutePaths.gallery,
            name: RouteNames.gallery,
            builder: (context, state) =>
                GalleryScreen(album: state.uri.queryParameters['album']),
          ),
          GoRoute(
            path: RoutePaths.eventDetailPattern,
            name: RouteNames.eventDetail,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return EventDetailScreen(
                eventId: id,
                on: state.uri.queryParameters['on'],
              );
            },
          ),
        ],
      ),

      // Sign-in and password reset sit outside the public shell so the header
      // navigation cannot lead a visitor in circles mid-authentication.
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      // --- Protected admin branch ---------------------------------------
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.admin,
            name: RouteNames.adminOverview,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminSiteSettings,
            name: RouteNames.adminSiteSettings,
            builder: (context, state) => const AdminSiteSettingsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminUsers,
            name: RouteNames.adminUsers,
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            // Declared before /admin/users/:id so "new" is not read as an id.
            path: RoutePaths.adminUserNew,
            builder: (context, state) => const AdminUserEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminUsers}/:id',
            name: RouteNames.adminUserEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminUserEditorScreen(userId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminRoles,
            name: RouteNames.adminRoles,
            builder: (context, state) => const AdminRolesScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminRoles}/:id',
            name: RouteNames.adminRolePermissions,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminRolePermissionsScreen(roleId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminTempleProfile,
            name: RouteNames.adminTempleProfile,
            builder: (context, state) => const AdminTempleProfileScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminCommittee,
            name: RouteNames.adminCommittee,
            builder: (context, state) => const AdminCommitteeScreen(),
          ),
          GoRoute(
            // Declared before /admin/committee/:id so "new" is not read as an id.
            path: RoutePaths.adminCommitteeNew,
            builder: (context, state) => const AdminCommitteeMemberScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminCommittee}/:id',
            name: RouteNames.adminCommitteeMember,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminCommitteeMemberScreen(memberId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminEvents,
            name: RouteNames.adminEvents,
            builder: (context, state) => const AdminEventsScreen(),
          ),
          GoRoute(
            // Declared before /admin/events/:id so "new" is not read as an id.
            path: RoutePaths.adminEventNew,
            builder: (context, state) => const AdminEventEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminEvents}/:id',
            name: RouteNames.adminEventEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminEventEditorScreen(eventId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminMedia,
            name: RouteNames.adminMedia,
            builder: (context, state) => const AdminMediaScreen(),
          ),
          GoRoute(
            // Declared before /admin/media/:id so "new" is not read as an id.
            path: RoutePaths.adminMediaNew,
            builder: (context, state) => const AdminMediaEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminMedia}/:id',
            name: RouteNames.adminMediaEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminMediaEditorScreen(mediaId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminAlbums,
            name: RouteNames.adminAlbums,
            builder: (context, state) => const AdminAlbumsScreen(),
          ),
          GoRoute(
            // Declared before /admin/albums/:id so "new" is not read as an id.
            path: RoutePaths.adminAlbumNew,
            builder: (context, state) => const AdminAlbumEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminAlbums}/:id',
            name: RouteNames.adminAlbumEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminAlbumEditorScreen(albumId: id);
            },
          ),
          GoRoute(
            // Declared before /admin/donations/:id so "new" is not read as an
            // id, and before the settings route can be mistaken for one.
            path: RoutePaths.adminDonationSettings,
            name: RouteNames.adminDonationSettings,
            builder: (context, state) => const AdminDonationSettingsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminDonations,
            name: RouteNames.adminDonations,
            builder: (context, state) => const AdminDonationsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminDonationNew,
            builder: (context, state) => const AdminDonationEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminDonations}/:id',
            name: RouteNames.adminDonationDetail,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminDonationEditorScreen(donationId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminAnnouncements,
            name: RouteNames.adminAnnouncements,
            builder: (context, state) => const AdminAnnouncementsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminAnnouncementNew,
            builder: (context, state) => const AdminAnnouncementEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminAnnouncements}/:id',
            name: RouteNames.adminAnnouncementEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminAnnouncementEditorScreen(announcementId: id);
            },
          ),
          // Accounts (Phase 9). `new` is declared before the `:id` pattern so
          // it is never parsed as a transaction whose id is the word "new".
          GoRoute(
            path: RoutePaths.adminAccounts,
            name: RouteNames.adminAccounts,
            builder: (context, state) => const AdminAccountsScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminAccountNew,
            builder: (context, state) => const AdminTransactionEditorScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminAccounts}/:id',
            name: RouteNames.adminAccountEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminTransactionEditorScreen(transactionId: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminAccountingCategories,
            name: RouteNames.adminAccountingCategories,
            builder: (context, state) =>
                const AdminAccountingCategoriesScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminAccountingSettings,
            name: RouteNames.adminAccountingSettings,
            builder: (context, state) => const AdminAccountingSettingsScreen(),
          ),
          // Reports (Phase 10). The key is a slug, matched narrowly so it can
          // never swallow a sibling route.
          GoRoute(
            path: RoutePaths.adminReports,
            name: RouteNames.adminReports,
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminReports}/:key',
            name: RouteNames.adminReport,
            builder: (context, state) {
              final key = state.pathParameters['key'];
              if (key == null || !RegExp(r'^[a-z0-9-]+$').hasMatch(key)) {
                return const NotFoundScreen();
              }
              return AdminReportScreen(reportKey: key);
            },
          ),
          GoRoute(
            path: RoutePaths.adminEnquiries,
            name: RouteNames.adminEnquiries,
            builder: (context, state) => const AdminEnquiriesScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminEnquiries}/:id',
            name: RouteNames.adminEnquiryDetail,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminEnquiryDetailScreen(id: id);
            },
          ),
          GoRoute(
            path: RoutePaths.adminPages,
            name: RouteNames.adminPages,
            builder: (context, state) => const AdminPagesScreen(),
          ),
          GoRoute(
            path: '${RoutePaths.adminPages}/:id',
            name: RouteNames.adminPageEditor,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const NotFoundScreen();
              return AdminPageEditorScreen(pageId: id);
            },
          ),
        ],
      ),

      // Declared last: go_router matches in order, so every specific route
      // above wins and only a genuinely unknown path reaches the CMS lookup.
      // This is what makes /about a clean, shareable URL.
      ShellRoute(
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.pagePattern,
            name: RouteNames.page,
            builder: (context, state) =>
                PageScreen(slug: state.pathParameters['slug'] ?? ''),
          ),
        ],
      ),
    ],
  );
});
