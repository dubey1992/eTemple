import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/domain/page_content.dart';
import 'package:rkt_web/features/content/presentation/admin_page_editor_screen.dart';
import 'package:rkt_web/features/content/presentation/admin_pages_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpAdmin(
  WidgetTester tester,
  Widget screen,
  FakeContentRepository content, {
  Size? surfaceSize,
}) async {
  await pumpScreen(
    tester,
    // These screens are shell children in the app; AdminShell supplies the
    // Scaffold that TextField and ScaffoldMessenger need.
    Scaffold(body: screen),
    surfaceSize: surfaceSize ?? const Size(1024, 1400),
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: testUser()),
      ),
      contentRepositoryProvider.overrideWithValue(content),
    ],
  );
}

void main() {
  group('AdminPagesScreen', () {
    testWidgets('lists pages with their publication status', (tester) async {
      final content = FakeContentRepository()
        ..adminPageList = [
          testEditablePage(id: 1, slug: 'home', status: PageStatus.published),
          testEditablePage(id: 2, slug: 'about'),
        ];

      await pumpAdmin(tester, const AdminPagesScreen(), content);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page-tile-home')), findsOneWidget);
      expect(find.byKey(const Key('page-tile-about')), findsOneWidget);
      expect(find.text('प्रकाशित'), findsOneWidget);
      expect(find.text('मसौदा'), findsOneWidget);
    });

    testWidgets('flags a page that exists in Hindi only', (tester) async {
      final content = FakeContentRepository()
        ..adminPageList = [
          testEditablePage(
            id: 1,
            slug: 'about',
            titleEn: null,
            contentEn: null,
          ),
        ];

      await pumpAdmin(tester, const AdminPagesScreen(), content);
      await tester.pumpAndSettle();

      expect(find.text('अंग्रेज़ी अनुपलब्ध'), findsOneWidget);
    });

    testWidgets(
      'a role without content permission sees the unauthorized state',
      (tester) async {
        // The server is what refuses; this asserts the UI reflects that refusal
        // rather than pretending the screen is empty.
        final content = FakeContentRepository(
          adminError: const AppException(code: ErrorCode.forbidden),
        );

        await pumpAdmin(tester, const AdminPagesScreen(), content);
        await tester.pumpAndSettle();

        expect(find.text('अनुमति नहीं है'), findsOneWidget);
      },
    );

    testWidgets('an outage offers a retry', (tester) async {
      final content = FakeContentRepository(
        adminError: const AppException(code: ErrorCode.network),
      );

      await pumpAdmin(tester, const AdminPagesScreen(), content);
      await tester.pumpAndSettle();

      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no pages', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminPagesScreen(),
        FakeContentRepository(),
      );
      await tester.pumpAndSettle();

      expect(find.text('अभी कोई जानकारी उपलब्ध नहीं है'), findsOneWidget);
    });
  });

  group('AdminPageEditorScreen', () {
    FakeContentRepository repositoryWithPage() =>
        FakeContentRepository()..adminPageList = [testEditablePage(id: 1)];

    testWidgets('loads both languages into the form', (tester) async {
      await pumpAdmin(
        tester,
        const AdminPageEditorScreen(pageId: 1),
        repositoryWithPage(),
      );
      await tester.pumpAndSettle();

      expect(find.text('हमारे बारे में'), findsWidgets);
      expect(find.text('About us'), findsOneWidget);
      expect(find.text('English content.'), findsOneWidget);
    });

    testWidgets('requires the Hindi fields but not the English ones', (
      tester,
    ) async {
      final content = repositoryWithPage();
      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor-title-hi')), '');
      await tester.enterText(find.byKey(const Key('editor-content-hi')), '');
      await tester.enterText(find.byKey(const Key('editor-title-en')), '');
      await tester.enterText(find.byKey(const Key('editor-content-en')), '');

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      expect(find.text('यह जानकारी आवश्यक है'), findsNWidgets(2));
      expect(content.saveCalls, 0);
    });

    testWidgets('saves, sending blank English fields as absent', (
      tester,
    ) async {
      final content = repositoryWithPage();
      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editor-title-en')), '   ');
      await tester.enterText(find.byKey(const Key('editor-content-en')), '');
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      expect(content.saveCalls, 1);
      final json = content.lastDraft!.toJson();
      // Absent, not empty string: the fallback rule keys on null.
      expect(json['title_en'], isNull);
      expect(json['content_en'], isNull);
      expect(json['title_hi'], 'हमारे बारे में');
    });

    testWidgets('publishing is a deliberate toggle', (tester) async {
      final content = repositoryWithPage();
      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      expect(find.text('मसौदा'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      expect(content.lastDraft!.status, PageStatus.published);
      expect(content.lastDraft!.toJson()['status'], 'published');
    });

    testWidgets('shows a server validation error against the right field', (
      tester,
    ) async {
      final content = repositoryWithPage()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'title_hi': ['The title hi field is required.'],
          },
        );

      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editor-error')), findsOneWidget);
      expect(find.text('The title hi field is required.'), findsOneWidget);
    });

    testWidgets('a rejected save shows a localized message', (tester) async {
      final content = repositoryWithPage()
        ..saveError = const AppException(code: ErrorCode.forbidden);

      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      expect(find.text('यह कार्य करने की अनुमति नहीं है।'), findsOneWidget);
    });

    testWidgets('disables the form while saving', (tester) async {
      final content = repositoryWithPage()
        ..delay = const Duration(milliseconds: 200);

      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('editor-save')),
      );
      expect(button.onPressed, isNull);

      await tester.pumpAndSettle();
    });

    testWidgets('a forbidden load shows the unauthorized state', (
      tester,
    ) async {
      final content = FakeContentRepository(
        adminError: const AppException(code: ErrorCode.forbidden),
      );

      await pumpAdmin(tester, const AdminPageEditorScreen(pageId: 1), content);
      await tester.pumpAndSettle();

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
    });
  });
}
