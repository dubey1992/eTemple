import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override is exported from the misc library in Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/app/routing/route_paths.dart';
import 'package:rkt_web/app/theme/app_theme.dart';
import 'package:rkt_web/features/temple/data/temple_providers.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import 'fake_temple_repository.dart';

/// Key on the stand-in screen the admin route renders in these tests.
const adminPlaceholderKey = Key('test-admin-placeholder');

/// Key on the stand-in screen the forgot-password route renders.
const forgotPasswordPlaceholderKey = Key('test-forgot-password-placeholder');

/// Key on the stand-in screen the committee-list route renders.
const committeeListPlaceholderKey = Key('test-committee-placeholder');

/// Pumps a single screen inside the real theme and localization setup.
///
/// A minimal router is provided so screens that navigate (the login screen, for
/// example) behave as they do in the application instead of throwing.
///
/// Since Phase 3 the temple's own name is CMS content read by the header, the
/// hero and even the sign-in page, so a stub temple repository is always
/// supplied — otherwise every widget test would attempt a real HTTP request.
/// Pass [temple] to script that profile, including making it fail.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = AppLocales.hindi,
  Size? surfaceSize,
  FakeTempleRepository? temple,
}) async {
  if (surfaceSize != null) {
    // Set the logical size directly: devicePixelRatio 1.0 makes the physical
    // size and the logical size the same, so the breakpoints under test are the
    // ones a browser at this width would apply.
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(path: RoutePaths.home, builder: (_, _) => child),
      GoRoute(
        path: RoutePaths.admin,
        builder: (_, _) =>
            const Scaffold(key: adminPlaceholderKey, body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (_, _) => const Scaffold(
          key: forgotPasswordPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminCommittee,
        builder: (_, _) => const Scaffold(
          key: committeeListPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminTempleProfile,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.committee,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        templeRepositoryProvider.overrideWithValue(
          temple ?? FakeTempleRepository(profile: testProfile()),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: locale,
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
}
