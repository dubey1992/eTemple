import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/routing/route_paths.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_destinations.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/shell/presentation/admin_menu.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpMenu(
  WidgetTester tester, {
  required Set<String> permissions,
  String location = RoutePaths.admin,
  Size surfaceSize = const Size(400, 900),
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: AdminMenu(location: location)),
    surfaceSize: surfaceSize,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: testUser(permissions: permissions)),
      ),
      contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations hi;

  setUpAll(() async {
    hi = await AppLocalizations.delegate.load(AppLocales.hindi);
  });

  group('AdminDestinations', () {
    test('every destination points inside the admin group', () {
      for (final destination in AdminDestinations.all(hi)) {
        expect(
          RoutePaths.isAdmin(destination.route),
          isTrue,
          reason: '${destination.id} is not an admin route',
        );
        expect(destination.title, isNotEmpty, reason: destination.id);
        expect(destination.description, isNotEmpty, reason: destination.id);
        expect(destination.permissions, isNotEmpty, reason: destination.id);
      }
    });

    test('ids are unique, because widget keys are built from them', () {
      final ids = AdminDestinations.all(hi).map((entry) => entry.id).toList();

      expect(ids.toSet().length, ids.length);
    });

    test('a module matches its own deep links and nothing else', () {
      final media = AdminDestinations.all(hi)
          .firstWhere((entry) => entry.id == 'media');

      expect(media.matches('/admin/media'), isTrue);
      expect(media.matches('/admin/media/12'), isTrue);
      // Without the boundary check this would light up the wrong entry.
      expect(media.matches('/admin/media-archive'), isFalse);
      expect(media.matches('/admin/donations'), isFalse);
    });
  });

  group('AdminMenu', () {
    testWidgets('offers only what the account may open', (tester) async {
      await pumpMenu(tester, permissions: const {Permissions.donationsView});

      expect(find.byKey(const Key('menu-donations')), findsOneWidget);
      // A Treasurer has no business in the enquiry inbox or the page editor.
      expect(find.byKey(const Key('menu-enquiries')), findsNothing);
      expect(find.byKey(const Key('menu-pages')), findsNothing);
    });

    testWidgets('an account with nothing still gets the dashboard', (
      tester,
    ) async {
      await pumpMenu(tester, permissions: const {});

      // Somewhere to stand, and a page that explains they may do nothing —
      // better than an empty rail with no way out.
      expect(find.byKey(const Key('menu-dashboard')), findsOneWidget);
      expect(find.byKey(const Key('menu-donations')), findsNothing);
    });

    testWidgets('the current module is marked, and only that one', (
      tester,
    ) async {
      await pumpMenu(
        tester,
        permissions: const {
          Permissions.enquiriesManage,
          Permissions.donationsView,
        },
        location: '/admin/enquiries/5',
      );

      ListTile tileFor(String key) => tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(ListTile),
        ),
      );

      // A deep link still highlights the module it belongs to.
      expect(tileFor('menu-enquiries').selected, isTrue);
      expect(tileFor('menu-donations').selected, isFalse);
      expect(tileFor('menu-dashboard').selected, isFalse);
    });

    testWidgets('the dashboard is marked only on an exact match', (
      tester,
    ) async {
      await pumpMenu(
        tester,
        permissions: const {Permissions.donationsView},
        location: RoutePaths.admin,
      );

      final dashboard = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(const Key('menu-dashboard')),
          matching: find.byType(ListTile),
        ),
      );
      expect(dashboard.selected, isTrue);
    });
  });

  group('AdminDashboardScreen', () {
    testWidgets('shows the same modules the menu does', (tester) async {
      const permissions = {
        Permissions.contentView,
        Permissions.donationsView,
        Permissions.enquiriesManage,
      };

      await pumpScreen(
        tester,
        const Scaffold(body: AdminDashboardScreen()),
        surfaceSize: const Size(1200, 1600),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(session: testUser(permissions: permissions)),
          ),
          contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
        ],
      );
      await tester.pumpAndSettle();

      // One list feeds both, so what is on the dashboard is what is in the
      // menu — the drift this catches is the whole reason the list is shared.
      final visible = AdminDestinations.visibleTo(
        hi,
        const PermissionSet(permissions),
      );

      for (final destination in visible) {
        expect(
          find.byKey(destination.key),
          findsOneWidget,
          reason: '${destination.id} is missing from the dashboard',
        );
      }
      expect(find.byKey(const Key('dash-users')), findsNothing);
    });
  });
}
