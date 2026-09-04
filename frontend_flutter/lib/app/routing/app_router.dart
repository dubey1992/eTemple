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
