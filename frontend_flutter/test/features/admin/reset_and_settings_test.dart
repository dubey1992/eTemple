import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/presentation/reset_password_screen.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/domain/site_settings.dart';
import 'package:rkt_web/features/content/presentation/admin_site_settings_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/pump_app.dart';

void main() {
  group('ResetPasswordScreen', () {
    Future<void> pumpReset(
      WidgetTester tester,
      FakeAuthRepository auth, {
      String token = 'a-valid-token',
      String email = 'member@thakurbari.test',
    }) async {
      await pumpScreen(
        tester,
        ResetPasswordScreen(token: token, email: email),
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a link missing its parameters says so instead of failing', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await pumpReset(tester, auth, token: '', email: '');

      expect(find.byKey(const Key('reset-link-invalid')), findsOneWidget);
      expect(find.byKey(const Key('reset-submit')), findsNothing);
      expect(auth.resetPasswordCalls, 0);
    });

    testWidgets('rejects a short password before calling the API', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await pumpReset(tester, auth);

      await tester.enterText(find.byKey(const Key('reset-password')), 'short');
      await tester.enterText(find.byKey(const Key('reset-confirm')), 'short');
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('पासवर्ड कम से कम 8 अक्षरों का होना चाहिए'),
        findsWidgets,
      );
      expect(auth.resetPasswordCalls, 0);
    });

    testWidgets('requires the two passwords to match', (tester) async {
      final auth = FakeAuthRepository();
      await pumpReset(tester, auth);

      await tester.enterText(
        find.byKey(const Key('reset-password')),
        'a-good-password',
      );
      await tester.enterText(
        find.byKey(const Key('reset-confirm')),
        'a-different-password',
      );
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(find.text('दोनों पासवर्ड एक जैसे नहीं हैं'), findsOneWidget);
      expect(auth.resetPasswordCalls, 0);
    });

    testWidgets('submits the token and password, then confirms', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await pumpReset(tester, auth);

      await tester.enterText(
        find.byKey(const Key('reset-password')),
        'a-good-password',
      );
      await tester.enterText(
        find.byKey(const Key('reset-confirm')),
        'a-good-password',
      );
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(auth.resetPasswordCalls, 1);
      expect(auth.lastToken, 'a-valid-token');
      expect(auth.lastPassword, 'a-good-password');
      expect(find.byKey(const Key('reset-done')), findsOneWidget);
      // The form is gone once it succeeded, so it cannot be submitted twice.
      expect(find.byKey(const Key('reset-submit')), findsNothing);
    });

    testWidgets('shows the server reason for an expired link', (tester) async {
      final auth = FakeAuthRepository(
        resetPasswordError: const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'token': ['This password reset link is invalid or has expired.'],
          },
        ),
      );
      await pumpReset(tester, auth);

      await tester.enterText(
        find.byKey(const Key('reset-password')),
        'a-good-password',
      );
      await tester.enterText(
        find.byKey(const Key('reset-confirm')),
        'a-good-password',
      );
      await tester.tap(find.byKey(const Key('reset-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reset-error')), findsOneWidget);
      expect(
        find.text('This password reset link is invalid or has expired.'),
        findsOneWidget,
      );
    });
  });

  group('AdminSiteSettingsScreen', () {
    Future<void> pumpSettings(
      WidgetTester tester,
      FakeContentRepository content,
    ) async {
      await pumpScreen(
        tester,
        Scaffold(body: const AdminSiteSettingsScreen()),
        surfaceSize: const Size(1024, 2000),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              session: testUser(permissions: {Permissions.contentManage}),
            ),
          ),
          contentRepositoryProvider.overrideWithValue(content),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('loads the current settings into the form', (tester) async {
      final content = FakeContentRepository()
        ..editableSettings = const EditableSiteSettings(
          taglineHi: 'भक्ति और सेवा',
          contactEmail: 'committee@thakurbari.test',
        );

      await pumpSettings(tester, content);

      expect(find.text('भक्ति और सेवा'), findsOneWidget);
      expect(find.text('committee@thakurbari.test'), findsOneWidget);
    });

    testWidgets('the address is not editable here; it links to the profile', (
      tester,
    ) async {
      // One source of truth: this screen must not offer a second set of
      // address fields once Phase 3 moved them to the temple profile.
      await pumpSettings(tester, FakeContentRepository());

      expect(find.byKey(const Key('settings-village')), findsNothing);
      expect(find.byKey(const Key('settings-district')), findsNothing);
      expect(find.byKey(const Key('settings-address-moved')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-open-temple-profile')),
        findsOneWidget,
      );
    });

    testWidgets('sends blank fields as absent, not empty strings', (
      tester,
    ) async {
      final content = FakeContentRepository()
        ..editableSettings = const EditableSiteSettings(taglineHi: 'पंक्ति');

      await pumpSettings(tester, content);

      await tester.enterText(
        find.byKey(const Key('settings-tagline_hi')),
        '  ',
      );
      await tester.enterText(
        find.byKey(const Key('settings-contact_email')),
        'committee@thakurbari.test',
      );
      await tester.tap(find.byKey(const Key('settings-save')));
      await tester.pumpAndSettle();

      expect(content.saveSettingsCalls, 1);
      final json = content.lastSettingsDraft!.toJson();
      // Absent, so the public site shows its empty state rather than a blank line.
      expect(json['tagline_hi'], isNull);
      expect(json['contact_email'], 'committee@thakurbari.test');
    });

    testWidgets('a refused save shows the unauthorized state on load', (
      tester,
    ) async {
      final content = FakeContentRepository(
        adminError: const AppException(code: ErrorCode.forbidden),
      );

      await pumpSettings(tester, content);

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
    });

    testWidgets('a server validation error is shown', (tester) async {
      final content = FakeContentRepository()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'contact_email': ['The contact email field must be a valid email.'],
          },
        );

      await pumpSettings(tester, content);

      await tester.tap(find.byKey(const Key('settings-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings-error')), findsOneWidget);
      expect(
        find.text('The contact email field must be a valid email.'),
        findsOneWidget,
      );
    });
  });
}
