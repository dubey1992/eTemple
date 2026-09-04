import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/temple/presentation/admin_committee_member_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_temple_repository.dart';
import '../../support/pump_app.dart';

/// The consent block in the member editor.
///
/// The rule itself lives on the server and is proven there by
/// `CommitteeConsentTest`. What is tested here is that the editor *shows* the
/// same rule rather than offering switches that the API will reject — a form
/// that silently disagrees with the server teaches people to distrust it.
Future<void> pumpMember(
  WidgetTester tester,
  FakeTempleRepository temple, {
  int? memberId,
  Set<String> permissions = const {Permissions.templeManage},
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: AdminCommitteeMemberScreen(memberId: memberId)),
    surfaceSize: const Size(1024, 3000),
    temple: temple,
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
  testWidgets('a new member starts unpublished and unconsented', (
    tester,
  ) async {
    await pumpMember(tester, FakeTempleRepository());

    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('member-published')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('member-has-consent')))
          .value,
      isFalse,
    );
  });

  testWidgets('the visibility switches are inert until consent is recorded', (
    tester,
  ) async {
    await pumpMember(tester, FakeTempleRepository());

    for (final key in const [
      Key('member-show-phone'),
      Key('member-show-email'),
      Key('member-show-photo'),
    ]) {
      expect(
        tester.widget<SwitchListTile>(find.byKey(key)).onChanged,
        isNull,
        reason: '$key must not be operable without consent',
      );
    }
    expect(find.byKey(const Key('member-consent-missing')), findsOneWidget);
  });

  testWidgets('recording consent enables the visibility switches', (
    tester,
  ) async {
    await pumpMember(tester, FakeTempleRepository());

    await tester.tap(find.byKey(const Key('member-has-consent')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('member-show-phone')))
          .onChanged,
      isNotNull,
    );
    expect(find.byKey(const Key('member-consent-missing')), findsNothing);
  });

  testWidgets('withdrawing consent turns every visibility switch off', (
    tester,
  ) async {
    final temple = FakeTempleRepository()
      ..adminMembers = [
        testAdminMember(
          id: 1,
          isPublished: true,
          hasConsent: true,
          showPhone: true,
          showEmail: true,
          showPhoto: true,
          consentRecordedAt: '2026-06-01T10:30:00+05:30',
        ),
      ];

    await pumpMember(tester, temple, memberId: 1);

    // All three start on.
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('member-show-phone')))
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('member-has-consent')));
    await tester.pumpAndSettle();

    for (final key in const [
      Key('member-show-phone'),
      Key('member-show-email'),
      Key('member-show-photo'),
    ]) {
      expect(
        tester.widget<SwitchListTile>(find.byKey(key)).value,
        isFalse,
        reason: '$key must be cleared when consent is withdrawn',
      );
    }
  });

  testWidgets('a withdrawal is submitted with all three flags off', (
    tester,
  ) async {
    final temple = FakeTempleRepository()
      ..adminMembers = [
        testAdminMember(
          id: 1,
          nameHi: 'राम प्रसाद',
          isPublished: true,
          hasConsent: true,
          showPhone: true,
          showEmail: true,
        ),
      ];

    await pumpMember(tester, temple, memberId: 1);

    await tester.tap(find.byKey(const Key('member-has-consent')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('member-save')));
    await tester.pumpAndSettle();

    final json = temple.lastMemberDraft!.toJson();
    expect(json['has_consent'], false);
    expect(json['show_phone_publicly'], false);
    expect(json['show_email_publicly'], false);
    expect(json['show_photo_publicly'], false);
  });

  testWidgets('the recorded consent date is shown', (tester) async {
    final temple = FakeTempleRepository()
      ..adminMembers = [
        testAdminMember(
          id: 1,
          hasConsent: true,
          consentRecordedAt: '2026-06-01T10:30:00+05:30',
        ),
      ];

    await pumpMember(tester, temple, memberId: 1);

    // The date, not the time of day: consent is a fact about a day.
    expect(find.textContaining('2026-06-01'), findsOneWidget);
  });

  testWidgets('a server refusal names the switch it rejected', (tester) async {
    // The server is the authority. If it refuses a combination this form
    // allowed, the editor must see which switch was at fault.
    final temple = FakeTempleRepository()
      ..saveError = const AppException(
        code: ErrorCode.validationFailed,
        fieldErrors: {
          'show_phone_publicly': [
            'This detail cannot be published until consent is recorded.',
          ],
        },
      );

    await pumpMember(tester, temple);

    await tester.enterText(find.byKey(const Key('member-name_hi')), 'सदस्य');
    await tester.enterText(
      find.byKey(const Key('member-designation_hi')),
      'सदस्य',
    );
    await tester.tap(find.byKey(const Key('member-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('member-error')), findsOneWidget);
    expect(
      find.text('This detail cannot be published until consent is recorded.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Hindi name and designation are required before the API is called',
    (tester) async {
      final temple = FakeTempleRepository();

      await pumpMember(tester, temple);

      await tester.tap(find.byKey(const Key('member-save')));
      await tester.pumpAndSettle();

      expect(find.text('यह जानकारी आवश्यक है'), findsNWidgets(2));
      expect(temple.createMemberCalls, 0);
    },
  );

  testWidgets('creating a member sends the typed values', (tester) async {
    final temple = FakeTempleRepository();

    await pumpMember(tester, temple);

    await tester.enterText(
      find.byKey(const Key('member-name_hi')),
      'राम प्रसाद',
    );
    await tester.enterText(
      find.byKey(const Key('member-designation_hi')),
      'सचिव',
    );
    await tester.tap(find.byKey(const Key('member-published')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('member-save')));
    await tester.pumpAndSettle();

    expect(temple.createMemberCalls, 1);
    final json = temple.lastMemberDraft!.toJson();
    expect(json['name_hi'], 'राम प्रसाद');
    expect(json['designation_hi'], 'सचिव');
    expect(json['is_published'], true);
  });

  testWidgets('deleting asks first and only then calls the API', (
    tester,
  ) async {
    // Deletion is erasure, not retirement; the dialog says so.
    final temple = FakeTempleRepository()
      ..adminMembers = [testAdminMember(id: 7)];

    await pumpMember(tester, temple, memberId: 7);

    await tester.tap(find.byKey(const Key('member-delete')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('member-delete-dialog')), findsOneWidget);
    expect(temple.deleteMemberCalls, 0);

    await tester.tap(find.byKey(const Key('member-delete-confirm')));
    await tester.pumpAndSettle();

    expect(temple.deleteMemberCalls, 1);
    expect(temple.lastDeletedId, 7);
  });

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    final temple = FakeTempleRepository()
      ..adminMembers = [testAdminMember(id: 7)];

    await pumpMember(tester, temple, memberId: 7);

    await tester.tap(find.byKey(const Key('member-delete')));
    await tester.pumpAndSettle();
    // The dialog's cancel button, found by type rather than by its translated
    // label: a text finder is only as wide as the glyphs that render.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('member-delete-dialog')),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(temple.deleteMemberCalls, 0);
  });

  testWidgets('without temple.manage the editor is read-only', (tester) async {
    final temple = FakeTempleRepository()
      ..adminMembers = [testAdminMember(id: 1)];

    await pumpMember(
      tester,
      temple,
      memberId: 1,
      permissions: const {Permissions.contentView},
    );

    expect(find.byKey(const Key('member-read-only')), findsOneWidget);
    expect(find.byKey(const Key('member-save')), findsNothing);
    expect(find.byKey(const Key('member-delete')), findsNothing);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('member-has-consent')))
          .onChanged,
      isNull,
    );
  });
}
