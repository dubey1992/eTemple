import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/admin/data/admin_providers.dart';
import 'package:rkt_web/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/presentation/login_screen.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/domain/site_settings.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/shell/presentation/public_shell.dart';

import '../../support/fake_admin_repository.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_temple_repository.dart';
import '../../support/pump_app.dart';

/// Phase 3's takeover of the temple's own name.
///
/// Before this phase the name and the village were compiled into the app's ARB
/// files. They are CMS content now: the profile is authoritative everywhere,
/// and the application string survives only as the shell fallback shown while
/// that request is in flight or after it fails.
Future<void> pumpShell(
  WidgetTester tester,
  FakeTempleRepository temple, {
  Size surfaceSize = const Size(1280, 2000),
  SiteSettings? settings,
}) async {
  await pumpScreen(
    tester,
    const PublicShell(child: HomeScreen()),
    surfaceSize: surfaceSize,
    temple: temple,
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      contentRepositoryProvider.overrideWithValue(
        FakeContentRepository(settings: settings ?? testSettings()),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the header takes its name from the temple profile', () {
    testWidgets('renders the configured name and locality', (tester) async {
      await pumpShell(
        tester,
        FakeTempleRepository(
          profile: testProfile(
            name: 'श्री राधा कृष्ण मंदिर',
            village: 'Amarpur Pankhoriya',
            panchayat: 'Kurma',
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(const Key('shell-temple-name')),
        ),
        findsOneWidget,
      );
      expect(find.text('श्री राधा कृष्ण मंदिर'), findsWidgets);
      expect(find.text('Amarpur Pankhoriya, Kurma'), findsWidgets);
    });

    testWidgets('editing the profile changes the header, not a code release', (
      tester,
    ) async {
      // The point of the phase: a different profile produces a different site
      // name with no change to the application.
      await pumpShell(
        tester,
        FakeTempleRepository(profile: testProfile(name: 'कोई और मंदिर')),
      );

      expect(find.text('कोई और मंदिर'), findsWidgets);
      expect(find.text('राधा कृष्ण ठाकुरबाड़ी'), findsNothing);
    });

    testWidgets('falls back to the app name when the profile is unwritten', (
      tester,
    ) async {
      await pumpShell(tester, FakeTempleRepository());

      expect(find.text('राधा कृष्ण ठाकुरबाड़ी'), findsWidgets);
    });

    testWidgets('falls back to the app name when the profile request fails', (
      tester,
    ) async {
      // A profile outage degrades the header; it must not blank it.
      await pumpShell(
        tester,
        FakeTempleRepository(
          profileError: const AppException(code: ErrorCode.network),
        ),
      );

      expect(find.text('राधा कृष्ण ठाकुरबाड़ी'), findsWidgets);
    });

    testWidgets('no village name is left compiled into the app', (
      tester,
    ) async {
      // The Phase 0-2 subtitle was the hardcoded "अमरपुर पंखोरिया, कुर्मा
      // पंचायत". With an unconfigured profile the line must be absent, not a
      // built-in village.
      await pumpShell(tester, FakeTempleRepository());

      expect(find.byKey(const Key('shell-temple-locality')), findsNothing);
      expect(find.byKey(const Key('hero-locality')), findsNothing);
      expect(find.textContaining('अमरपुर'), findsNothing);
    });

    testWidgets('the footer uses the profile identity when none is written', (
      tester,
    ) async {
      await pumpShell(
        tester,
        FakeTempleRepository(
          profile: testProfile(name: 'श्री राधा कृष्ण मंदिर'),
        ),
        // No footer line written, so the footer falls back to the temple's own
        // identity — from the profile, not from a compiled string.
        settings: testSettings(footer: null),
      );

      final footer = tester.widget<Text>(
        find.byKey(const Key('public-footer')),
      );
      expect(footer.data, contains('श्री राधा कृष्ण मंदिर'));
      expect(footer.data, contains('Amarpur Pankhoriya'));
    });
  });

  group('the sign-in page is named by the temple', () {
    testWidgets('uses the profile name', (tester) async {
      await pumpScreen(
        tester,
        const LoginScreen(),
        temple: FakeTempleRepository(
          profile: testProfile(name: 'श्री राधा कृष्ण मंदिर'),
        ),
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('श्री राधा कृष्ण मंदिर'), findsOneWidget);
    });

    testWidgets('falls back to the app name before the profile arrives', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const LoginScreen(),
        temple: FakeTempleRepository(),
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('राधा कृष्ण ठाकुरबाड़ी'), findsOneWidget);
    });
  });

  group('the dashboard offers the Phase 3 modules', () {
    Future<void> pumpDashboard(
      WidgetTester tester,
      Set<String> permissions,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(body: AdminDashboardScreen()),
        surfaceSize: const Size(1280, 1600),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(session: testUser(permissions: permissions)),
          ),
          adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows both entries to someone who may edit them', (
      tester,
    ) async {
      await pumpDashboard(tester, const {Permissions.templeManage});

      expect(find.byKey(const Key('dash-temple-profile')), findsOneWidget);
      expect(find.byKey(const Key('dash-committee')), findsOneWidget);
    });

    testWidgets('shows them to a viewer, who may read but not change', (
      tester,
    ) async {
      // Reading the profile and committee is gated on content.view server-side,
      // so offering the door here matches what the API will allow.
      await pumpDashboard(tester, const {Permissions.contentView});

      expect(find.byKey(const Key('dash-temple-profile')), findsOneWidget);
      expect(find.byKey(const Key('dash-committee')), findsOneWidget);
    });

    testWidgets('hides them from an account with neither permission', (
      tester,
    ) async {
      await pumpDashboard(tester, const {Permissions.donationsView});

      expect(find.byKey(const Key('dash-temple-profile')), findsNothing);
      expect(find.byKey(const Key('dash-committee')), findsNothing);
    });
  });
}
