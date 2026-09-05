import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/app/routing/app_router.dart';
import 'package:rkt_web/app/routing/route_paths.dart';
import 'package:rkt_web/app/theme/app_theme.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/domain/auth_user.dart';
import 'package:rkt_web/features/auth/presentation/auth_controller.dart';
import 'package:rkt_web/features/auth/presentation/login_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/shell/presentation/not_found_screen.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/donations/data/donation_providers.dart';
import 'package:rkt_web/features/events/data/event_providers.dart';
import 'package:rkt_web/features/media/data/media_providers.dart';
import 'package:rkt_web/features/temple/data/temple_providers.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_content_repository.dart';
import '../support/fake_donation_repository.dart';
import '../support/fake_event_repository.dart';
import '../support/fake_media_repository.dart';
import '../support/fake_temple_repository.dart';
import '../support/no_network.dart';

/// Boots the real router against a scripted repository and returns both so a
/// test can navigate and then assert on what the guard did.
Future<(GoRouter, ProviderContainer)> bootRouter(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  // The real router builds the real screens, and those read the temple profile,
  // the calendar, the gallery and the donation details. Every repository is
  // faked and the HTTP client refuses to connect, so booting the router cannot
  // reach the network.
  final container = ProviderContainer.test(
    overrides: [
      noNetworkOverride,
      authRepositoryProvider.overrideWithValue(repository),
      contentRepositoryProvider.overrideWithValue(
        FakeContentRepository(
          pages: {'about': testPage()},
          settings: testSettings(),
        ),
      ),
      templeRepositoryProvider.overrideWithValue(
        FakeTempleRepository(profile: testProfile()),
      ),
      eventRepositoryProvider.overrideWithValue(FakeEventRepository()),
      mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
      donationRepositoryProvider.overrideWithValue(FakeDonationRepository()),
    ],
  );

  // Let the session restore complete before the first frame, as it would on a
  // real page load.
  await container.read(authControllerProvider.future);

  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: AppLocales.hindi,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();

  return (router, container);
}

String currentLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('the public home page is reachable without signing in', (
    tester,
  ) async {
    final (router, _) = await bootRouter(tester, FakeAuthRepository());

    expect(currentLocation(router), RoutePaths.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a guest is redirected away from the admin area', (tester) async {
    final (router, _) = await bootRouter(tester, FakeAuthRepository());

    router.go(RoutePaths.admin);
    await tester.pumpAndSettle();

    expect(currentLocation(router), RoutePaths.login);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AdminDashboardScreen), findsNothing);
  });

  testWidgets('an active user reaches the admin area', (tester) async {
    final (router, _) = await bootRouter(
      tester,
      FakeAuthRepository(session: testUser()),
    );

    router.go(RoutePaths.admin);
    await tester.pumpAndSettle();

    expect(currentLocation(router), RoutePaths.admin);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
  });

  testWidgets('an inactive account is treated as a guest by the guard', (
    tester,
  ) async {
    final (router, _) = await bootRouter(
      tester,
      FakeAuthRepository(session: testUser(status: AccountStatus.inactive)),
    );

    router.go(RoutePaths.admin);
    await tester.pumpAndSettle();

    expect(currentLocation(router), RoutePaths.login);
  });

  testWidgets(
    'a signed-in user is sent from the login page to the admin area',
    (tester) async {
      final (router, _) = await bootRouter(
        tester,
        FakeAuthRepository(session: testUser()),
      );

      router.go(RoutePaths.login);
      await tester.pumpAndSettle();

      expect(currentLocation(router), RoutePaths.admin);
    },
  );

  testWidgets('signing in re-evaluates the guard', (tester) async {
    final repository = FakeAuthRepository();
    final (router, container) = await bootRouter(tester, repository);

    router.go(RoutePaths.admin);
    await tester.pumpAndSettle();
    expect(currentLocation(router), RoutePaths.login);

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'committee@thakurbari.in', password: 'a-valid-password');
    await tester.pumpAndSettle();

    router.go(RoutePaths.admin);
    await tester.pumpAndSettle();
    expect(currentLocation(router), RoutePaths.admin);
  });

  testWidgets('signing out closes the admin area again', (tester) async {
    final (router, container) = await bootRouter(
      tester,
      FakeAuthRepository(session: testUser()),
    );

    router.go(RoutePaths.admin);
    await tester.pumpAndSettle();
    expect(currentLocation(router), RoutePaths.admin);

    await container.read(authControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(currentLocation(router), RoutePaths.login);
  });

  testWidgets('an unknown deep link renders the not-found screen', (
    tester,
  ) async {
    final (router, _) = await bootRouter(tester, FakeAuthRepository());

    router.go('/no-such-page');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  group('RoutePaths.isAdmin', () {
    test('matches the admin group and nothing else', () {
      expect(RoutePaths.isAdmin('/admin'), isTrue);
      expect(RoutePaths.isAdmin('/admin/users'), isTrue);
      expect(RoutePaths.isAdmin('/administration'), isFalse);
      expect(RoutePaths.isAdmin('/'), isFalse);
      expect(RoutePaths.isAdmin('/login'), isFalse);
    });
  });
}
