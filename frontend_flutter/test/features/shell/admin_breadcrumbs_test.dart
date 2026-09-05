import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/app/routing/route_paths.dart';
import 'package:rkt_web/features/shell/presentation/admin_breadcrumbs.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import '../../support/pump_app.dart';

/// The trail is a pure function of the path, so the whole navigation map can be
/// checked without pumping a widget. Every admin route must produce a trail —
/// a route that does not is a screen with no way back.
void main() {
  late AppLocalizations hi;
  late AppLocalizations en;

  setUpAll(() async {
    hi = await AppLocalizations.delegate.load(AppLocales.hindi);
    en = await AppLocalizations.delegate.load(AppLocales.english);
  });

  group('adminTrail', () {
    test('the dashboard is a single crumb with nothing to go back to', () {
      final trail = adminTrail(RoutePaths.admin, hi);

      expect(trail, hasLength(1));
      expect(trail.single.label, hi.adminDashboardTitle);
      expect(trail.single.isLink, isFalse);
    });

    test('a section page links back to the dashboard', () {
      final trail = adminTrail(RoutePaths.adminCommittee, hi);

      expect(trail.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.navCommittee,
      ]);
      expect(trail.first.route, RoutePaths.admin);
      // The page you are on is not a link to itself.
      expect(trail.last.isLink, isFalse);
    });

    test('a detail page links back to its list', () {
      final trail = adminTrail(RoutePaths.adminCommitteeMember(7), hi);

      expect(trail.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.navCommittee,
        hi.memberEdit,
      ]);
      expect(trail[1].route, RoutePaths.adminCommittee);
      expect(trail.last.isLink, isFalse);
    });

    test('a create page is labelled as new, not as editing', () {
      expect(
        adminTrail(RoutePaths.adminCommitteeNew, hi).last.label,
        hi.memberNew,
      );
      expect(adminTrail(RoutePaths.adminUserNew, hi).last.label, hi.userNew);
      expect(adminTrail(RoutePaths.adminEventNew, hi).last.label, hi.eventNew);
    });

    test('the events branch leads back through the calendar', () {
      final trail = adminTrail(RoutePaths.adminEventEditor(4), hi);

      expect(trail.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.navEvents,
        hi.eventEdit,
      ]);
      expect(trail[1].route, RoutePaths.adminEvents);
    });

    test('the media editor trail goes back to the library', () {
      final trail = adminTrail(RoutePaths.adminMediaEditor(4), hi);

      expect(trail.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.navMedia,
        hi.mediaEdit,
      ]);
      expect(trail[1].route, RoutePaths.adminMedia);
    });

    test('an album editor goes back through the library, not to the top', () {
      // Albums are reached from the library, so that is where back should
      // land — one step, not all the way home.
      final trail = adminTrail(RoutePaths.adminAlbumEditor(2), hi);

      expect(trail.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.navMedia,
        hi.navAlbums,
        hi.albumEdit,
      ]);
      expect(trail.last.route, isNull);
      expect(trail[2].route, RoutePaths.adminAlbums);
    });

    test('the donation settings go back through the register', () {
      // They are reached from the register, so that is where back should land
      // — the bank details are part of running the money, not of the dashboard.
      final trail = adminTrail(RoutePaths.adminDonationSettings, hi);

      expect(trail.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.navDonations,
        hi.navDonationSettings,
      ]);
      expect(trail[1].route, RoutePaths.adminDonations);
      expect(trail.last.isLink, isFalse);
    });

    /// The categories and the settings are reached from the ledger, so the
    /// ledger — not the dashboard — is where "back" lands.
    test('the accounting screens sit under the ledger', () {
      final categories = adminTrail(RoutePaths.adminAccountingCategories, hi);

      expect(categories.map((c) => c.label), [
        hi.adminDashboardTitle,
        hi.accountsTitle,
        hi.accountsCategoriesTitle,
      ]);
      expect(categories[1].route, RoutePaths.adminAccounts);
      expect(categories.last.isLink, isFalse);

      final settings = adminTrail(RoutePaths.adminAccountingSettings, hi);
      expect(settings[1].route, RoutePaths.adminAccounts);
    });

    test('every admin route produces a trail', () {
      final routes = <String>[
        RoutePaths.admin,
        RoutePaths.adminPages,
        RoutePaths.adminPageEditor(3),
        RoutePaths.adminSiteSettings,
        RoutePaths.adminTempleProfile,
        RoutePaths.adminCommittee,
        RoutePaths.adminCommitteeNew,
        RoutePaths.adminCommitteeMember(1),
        RoutePaths.adminUsers,
        RoutePaths.adminUserNew,
        RoutePaths.adminUserEditor(1),
        RoutePaths.adminRoles,
        RoutePaths.adminRolePermissions(1),
        RoutePaths.adminEvents,
        RoutePaths.adminEventNew,
        RoutePaths.adminEventEditor(1),
        RoutePaths.adminMedia,
        RoutePaths.adminMediaNew,
        RoutePaths.adminMediaEditor(1),
        RoutePaths.adminAlbums,
        RoutePaths.adminAlbumNew,
        RoutePaths.adminAlbumEditor(1),
        RoutePaths.adminDonations,
        RoutePaths.adminDonationNew,
        RoutePaths.adminDonationDetail(1),
        RoutePaths.adminDonationSettings,
        RoutePaths.adminEnquiries,
        RoutePaths.adminEnquiryDetail(1),
        RoutePaths.adminAnnouncements,
        RoutePaths.adminAnnouncementNew,
        RoutePaths.adminAnnouncementEditor(1),
        RoutePaths.adminAccounts,
        RoutePaths.adminAccountNew,
        RoutePaths.adminAccountDetail(1),
        RoutePaths.adminAccountingCategories,
        RoutePaths.adminAccountingSettings,
        RoutePaths.adminReports,
        RoutePaths.adminReport('donations'),
      ];

      for (final route in routes) {
        final trail = adminTrail(route, hi);
        expect(trail, isNotEmpty, reason: '$route has no breadcrumb trail');
        expect(
          trail.first.label,
          hi.adminDashboardTitle,
          reason: '$route does not lead home',
        );
        for (final crumb in trail) {
          expect(crumb.label, isNotEmpty, reason: '$route has a blank crumb');
        }
      }
    });

    test('a trailing slash and a query string do not change the trail', () {
      final plain = adminTrail(RoutePaths.adminUsers, hi).map((c) => c.label);

      expect(adminTrail('/admin/users/', hi).map((c) => c.label), plain);
      expect(adminTrail('/admin/users?page=2', hi).map((c) => c.label), plain);
    });

    test('an unmapped admin path still offers a way home', () {
      final trail = adminTrail('/admin/something-new', hi);

      expect(trail, hasLength(1));
      expect(trail.single.route, RoutePaths.admin);
    });

    test('public routes have no admin trail', () {
      expect(adminTrail(RoutePaths.home, hi), isEmpty);
      expect(adminTrail(RoutePaths.committee, hi), isEmpty);
      expect(adminTrail(RoutePaths.events, hi), isEmpty);
      expect(adminTrail(RoutePaths.eventDetail(3), hi), isEmpty);
      expect(adminTrail(RoutePaths.login, hi), isEmpty);
    });

    test('the labels follow the active language', () {
      final trail = adminTrail(RoutePaths.adminCommittee, en);

      expect(trail.map((c) => c.label), [
        en.adminDashboardTitle,
        en.navCommittee,
      ]);
      expect(trail.last.label, isNot(hi.navCommittee));
    });
  });

  group('AdminBreadcrumbs', () {
    testWidgets('renders nothing on the dashboard itself', (tester) async {
      await pumpScreen(
        tester,
        const Scaffold(body: AdminBreadcrumbs(location: RoutePaths.admin)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('breadcrumb-back')), findsNothing);
    });

    testWidgets('renders the trail and a back control on a detail page', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: AdminBreadcrumbs(location: RoutePaths.adminCommitteeMember(7)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('breadcrumb-back')), findsOneWidget);
      expect(find.byKey(const Key('breadcrumb-0')), findsOneWidget);
      expect(find.byKey(const Key('breadcrumb-1')), findsOneWidget);
      expect(find.byKey(const Key('breadcrumb-2')), findsOneWidget);
      expect(find.text(hi.memberEdit), findsOneWidget);
    });

    testWidgets('back goes to the list, not to the dashboard', (tester) async {
      // The nearest linked ancestor is the committee list; jumping all the way
      // home would lose the reader's place.
      await pumpScreen(
        tester,
        Scaffold(
          body: AdminBreadcrumbs(location: RoutePaths.adminCommitteeMember(7)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('breadcrumb-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(committeeListPlaceholderKey), findsOneWidget);
    });

    testWidgets('a crumb navigates to its section', (tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: AdminBreadcrumbs(location: RoutePaths.adminCommitteeMember(7)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('breadcrumb-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(committeeListPlaceholderKey), findsOneWidget);
    });

    testWidgets('the dashboard crumb goes home', (tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: AdminBreadcrumbs(location: RoutePaths.adminCommitteeMember(7)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('breadcrumb-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(adminPlaceholderKey), findsOneWidget);
    });
  });
}
