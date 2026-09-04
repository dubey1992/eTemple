import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/presentation/login_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpLogin(
  WidgetTester tester,
  FakeAuthRepository repository, {
  Locale locale = AppLocales.hindi,
}) {
  return pumpScreen(
    tester,
    const LoginScreen(),
    locale: locale,
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
}

Future<void> fillCredentials(
  WidgetTester tester, {
  String email = 'committee@thakurbari.in',
  String password = 'a-valid-password',
}) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
}

void main() {
  testWidgets('renders in Hindi by default', (tester) async {
    await pumpLogin(tester, FakeAuthRepository());

    expect(find.text('प्रबंधन लॉगिन'), findsOneWidget);
    expect(find.text('ईमेल'), findsOneWidget);
    expect(find.text('पासवर्ड'), findsOneWidget);
    expect(find.text('साइन इन'), findsOneWidget);
  });

  testWidgets('renders in English when that locale is active', (tester) async {
    await pumpLogin(tester, FakeAuthRepository(), locale: AppLocales.english);

    expect(find.text('Administration sign in'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
  });

  testWidgets('blocks submission and shows messages for empty fields', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await pumpLogin(tester, repository);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('यह जानकारी आवश्यक है'), findsNWidgets(2));
    expect(repository.signInCalls, 0);
  });

  testWidgets('rejects a malformed e-mail before calling the API', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await pumpLogin(tester, repository);

    await fillCredentials(tester, email: 'not-an-email');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('कृपया वैध ईमेल पता दर्ज करें'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('rejects a short password before calling the API', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await pumpLogin(tester, repository);

    await fillCredentials(tester, password: 'short');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('पासवर्ड कम से कम 8 अक्षरों का होना चाहिए'),
      findsOneWidget,
    );
    expect(repository.signInCalls, 0);
  });

  testWidgets('submits valid credentials to the repository', (tester) async {
    final repository = FakeAuthRepository();
    await pumpLogin(tester, repository);

    await fillCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(repository.lastEmail, 'committee@thakurbari.in');
    expect(repository.lastPassword, 'a-valid-password');
  });

  testWidgets(
    'shows a progress indicator and disables the button while in flight',
    (tester) async {
      final repository = FakeAuthRepository(
        delay: const Duration(milliseconds: 200),
      );
      await pumpLogin(tester, repository);

      await fillCredentials(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('login-submit')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('login-submit')),
      );
      expect(button.onPressed, isNull);

      await tester.pumpAndSettle();
    },
  );

  testWidgets('shows a localized message for invalid credentials', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      signInError: const AppException(
        code: ErrorCode.invalidCredentials,
        debugMessage: 'These credentials do not match our records.',
      ),
    );
    await pumpLogin(tester, repository);

    await fillCredentials(tester, password: 'wrong-password');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('ईमेल या पासवर्ड गलत है।'), findsOneWidget);
    // The server's English text is never surfaced to the visitor.
    expect(
      find.text('These credentials do not match our records.'),
      findsNothing,
    );
  });

  testWidgets('shows a distinct message for a blocked account', (tester) async {
    final repository = FakeAuthRepository(
      signInError: const AppException(code: ErrorCode.accountBlocked),
    );
    await pumpLogin(tester, repository);

    await fillCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('यह खाता अवरुद्ध कर दिया गया है। कृपया समिति से संपर्क करें।'),
      findsOneWidget,
    );
  });

  testWidgets('shows an offline message when the network is unavailable', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      signInError: const AppException(code: ErrorCode.network),
    );
    await pumpLogin(tester, repository);

    await fillCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('नेटवर्क उपलब्ध नहीं है। कृपया अपना इंटरनेट कनेक्शन जाँचें।'),
      findsOneWidget,
    );
  });

  testWidgets('surfaces server-side field errors on the right input', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      signInError: const AppException(
        code: ErrorCode.validationFailed,
        fieldErrors: {
          'email': ['The email field is required.'],
        },
      ),
    );
    await pumpLogin(tester, repository);

    await fillCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('The email field is required.'), findsOneWidget);
  });

  testWidgets('the password is obscured until the reveal control is used', (
    tester,
  ) async {
    await pumpLogin(tester, FakeAuthRepository());

    TextField passwordField() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('login-password')),
        matching: find.byType(TextField),
      ),
    );

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets(
    'lays out without overflow at mobile, tablet and desktop widths',
    (tester) async {
      for (final size in const [
        Size(360, 780),
        Size(768, 1024),
        Size(1440, 900),
      ]) {
        await pumpScreen(
          tester,
          const LoginScreen(),
          surfaceSize: size,
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'login screen overflowed at $size',
        );
        expect(find.byKey(const Key('login-submit')), findsOneWidget);
      }
    },
  );
}
