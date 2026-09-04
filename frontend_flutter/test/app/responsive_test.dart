import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/widgets/breakpoints.dart';
import 'package:rkt_web/core/widgets/language_switch.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/shell/presentation/public_shell.dart';

import 'package:rkt_web/features/content/data/content_providers.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_content_repository.dart';
import '../support/pump_app.dart';

const _mobile = Size(360, 780);
const _tablet = Size(768, 1024);
const _desktop = Size(1440, 900);

FakeContentRepository contentRepository() => FakeContentRepository(
  pages: {'about': testPage()},
  settings: testSettings(),
);

void main() {
  group('Breakpoints', () {
    test('classifies widths at and around each boundary', () {
      expect(Breakpoints.forWidth(320), FormFactor.mobile);
      expect(Breakpoints.forWidth(599), FormFactor.mobile);
      expect(Breakpoints.forWidth(600), FormFactor.tablet);
      expect(Breakpoints.forWidth(1023), FormFactor.tablet);
      expect(Breakpoints.forWidth(1024), FormFactor.desktop);
      expect(Breakpoints.forWidth(1920), FormFactor.desktop);
    });

    test('only mobile is treated as compact', () {
      expect(FormFactor.mobile.isCompact, isTrue);
      expect(FormFactor.tablet.isCompact, isFalse);
      expect(FormFactor.desktop.isCompact, isFalse);
    });
  });

  group('public shell layout', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      await pumpScreen(
        tester,
        const PublicShell(child: HomeScreen()),
        surfaceSize: size,
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          contentRepositoryProvider.overrideWithValue(contentRepository()),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders without overflow at every breakpoint', (tester) async {
      for (final size in const [_mobile, _tablet, _desktop]) {
        await pumpAt(tester, size);

        expect(
          tester.takeException(),
          isNull,
          reason: 'public shell overflowed at $size',
        );
        expect(find.byType(LanguageSwitch), findsOneWidget);
      }
    });

    testWidgets('uses the compact language control on a phone only', (
      tester,
    ) async {
      await pumpAt(tester, _mobile);
      expect(
        tester.widget<LanguageSwitch>(find.byType(LanguageSwitch)).compact,
        isTrue,
      );

      await pumpAt(tester, _desktop);
      expect(
        tester.widget<LanguageSwitch>(find.byType(LanguageSwitch)).compact,
        isFalse,
      );
    });

    testWidgets('hides the locality line in the header on a phone', (
      tester,
    ) async {
      // The line is the temple profile's village and panchayat, not a compiled
      // string, so this also proves the profile reaches the header.
      await pumpAt(tester, _desktop);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(const Key('shell-temple-locality')),
        ),
        findsOneWidget,
      );

      await pumpAt(tester, _mobile);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(const Key('shell-temple-locality')),
        ),
        findsNothing,
      );
    });
  });

  group('shared state views', () {
    testWidgets('loading announces itself and is localized', (tester) async {
      await pumpScreen(tester, const Scaffold(body: LoadingView()));
      // Not pumpAndSettle: the progress indicator animates indefinitely.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('लोड हो रहा है…'), findsOneWidget);
    });

    testWidgets('empty shows the localized empty message', (tester) async {
      await pumpScreen(tester, const Scaffold(body: EmptyView()));
      await tester.pumpAndSettle();

      expect(find.text('अभी कोई जानकारी उपलब्ध नहीं है'), findsOneWidget);
    });

    testWidgets('error shows a user-safe message and an optional retry', (
      tester,
    ) async {
      var retries = 0;

      await pumpScreen(
        tester,
        Scaffold(
          body: ErrorView(
            error: const AppException(
              code: ErrorCode.network,
              debugMessage: 'SocketException: failed host lookup',
            ),
            onRetry: () => retries++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('नेटवर्क उपलब्ध नहीं है। कृपया अपना इंटरनेट कनेक्शन जाँचें।'),
        findsOneWidget,
      );
      expect(find.text('SocketException: failed host lookup'), findsNothing);

      await tester.tap(find.text('पुनः प्रयास करें'));
      expect(retries, 1);
    });

    testWidgets('error hides the retry action when none is offered', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(
          body: ErrorView(error: AppException(code: ErrorCode.serverError)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('पुनः प्रयास करें'), findsNothing);
    });

    testWidgets('unauthorized explains the situation without leaking detail', (
      tester,
    ) async {
      await pumpScreen(tester, const Scaffold(body: UnauthorizedView()));
      await tester.pumpAndSettle();

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
      expect(
        find.text('इस पृष्ठ को देखने के लिए आपके पास आवश्यक अनुमति नहीं है।'),
        findsOneWidget,
      );
    });
  });
}
