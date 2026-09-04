import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/temple/domain/temple_profile.dart';
import 'package:rkt_web/features/temple/presentation/admin_committee_screen.dart';
import 'package:rkt_web/features/temple/presentation/admin_temple_profile_screen.dart';
import 'package:rkt_web/features/temple/presentation/committee_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_temple_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpTemple(
  WidgetTester tester,
  Widget screen,
  FakeTempleRepository temple, {
  Set<String> permissions = const {Permissions.templeManage},
  Size surfaceSize = const Size(1024, 2400),
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize,
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
  group('CommitteeScreen (public)', () {
    testWidgets('lists the members the server returned', (tester) async {
      final temple = FakeTempleRepository(
        members: [
          testMember(id: 1, name: 'राम प्रसाद', designation: 'अध्यक्ष'),
          testMember(id: 2, name: 'सीता देवी', designation: 'कोषाध्यक्ष'),
        ],
      );

      await pumpTemple(tester, const CommitteeScreen(), temple);

      expect(find.text('राम प्रसाद'), findsOneWidget);
      expect(find.text('सीता देवी'), findsOneWidget);
      expect(find.byKey(const Key('committee-card-1')), findsOneWidget);
      expect(find.byKey(const Key('committee-card-2')), findsOneWidget);
    });

    testWidgets('shows only the personal details the server sent', (
      tester,
    ) async {
      // The consent decision is the server's; the client renders what arrives
      // and has no way to reveal what did not. A withheld detail is shown as
      // "NA" so every card keeps the same shape — that says nothing about the
      // member, only that the value was not published.
      final temple = FakeTempleRepository(
        members: [
          testMember(id: 1, phone: '+91 90000 00000'),
          testMember(id: 2, name: 'दूसरा सदस्य'),
        ],
      );

      await pumpTemple(tester, const CommitteeScreen(), temple);

      expect(find.text('+91 90000 00000'), findsOneWidget);
      // Two members, two contact rows each: nothing is hidden structurally.
      expect(find.byIcon(Icons.call_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.mail_outline), findsNWidgets(2));
      // One phone was sent; the other phone and both e-mails were not.
      expect(find.text('NA'), findsNWidgets(3));
    });

    testWidgets('every card in a row is the same height', (tester) async {
      // One member has a bio and a tenure, the other has neither. Before the
      // rows were built by hand, Wrap sized each card independently and left
      // them ragged.
      final temple = FakeTempleRepository(
        members: [
          testMember(
            id: 1,
            bio: 'एक लम्बा परिचय जो कई पंक्तियों में फैलता है।',
            tenureStart: '2024-04-01',
          ),
          testMember(id: 2, name: 'दूसरा सदस्य'),
        ],
      );

      await pumpTemple(tester, const CommitteeScreen(), temple);

      final first = tester.getSize(find.byKey(const Key('committee-card-1')));
      final second = tester.getSize(find.byKey(const Key('committee-card-2')));

      expect(second.height, first.height);
      expect(second.width, first.width);
    });

    testWidgets('an empty committee is a coming-soon state, not an error', (
      tester,
    ) async {
      await pumpTemple(tester, const CommitteeScreen(), FakeTempleRepository());

      expect(find.byKey(const Key('committee-coming-soon')), findsOneWidget);
    });

    testWidgets('an outage offers a retry', (tester) async {
      final temple = FakeTempleRepository(
        committeeError: const AppException(code: ErrorCode.network),
      );

      await pumpTemple(tester, const CommitteeScreen(), temple);

      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });

    testWidgets('a Hindi-only member shows the fallback notice', (
      tester,
    ) async {
      final temple = FakeTempleRepository(
        members: [testMember(id: 1, fallbackUsed: true)],
      );

      await pumpTemple(tester, const CommitteeScreen(), temple);

      expect(find.byKey(const Key('fallback-notice')), findsOneWidget);
    });

    testWidgets('shows the tenure when the server sent it', (tester) async {
      final temple = FakeTempleRepository(
        members: [testMember(id: 1, tenureStart: '2024-04-01')],
      );

      await pumpTemple(tester, const CommitteeScreen(), temple);

      expect(find.textContaining('2024-04-01'), findsOneWidget);
    });
  });

  group('AdminTempleProfileScreen', () {
    testWidgets('loads the profile into the form', (tester) async {
      final temple = FakeTempleRepository()
        ..editableProfile = EditableTempleProfile.fromJson({
          'name_hi': 'राधा कृष्ण ठाकुरबाड़ी',
          'village': 'Amarpur Pankhoriya',
        });

      await pumpTemple(tester, const AdminTempleProfileScreen(), temple);

      expect(find.text('राधा कृष्ण ठाकुरबाड़ी'), findsOneWidget);
      expect(find.text('Amarpur Pankhoriya'), findsOneWidget);
    });

    testWidgets('sends blank fields as absent, not empty strings', (
      tester,
    ) async {
      final temple = FakeTempleRepository()
        ..editableProfile = EditableTempleProfile.fromJson({
          'name_hi': 'राधा कृष्ण ठाकुरबाड़ी',
        });

      await pumpTemple(tester, const AdminTempleProfileScreen(), temple);

      await tester.enterText(find.byKey(const Key('temple-name_hi')), '  ');
      await tester.enterText(
        find.byKey(const Key('temple-village')),
        'Amarpur Pankhoriya',
      );
      await tester.tap(find.byKey(const Key('temple-save')));
      await tester.pumpAndSettle();

      expect(temple.saveProfileCalls, 1);
      final json = temple.lastProfileDraft!.toJson();
      expect(json['name_hi'], isNull);
      expect(json['village'], 'Amarpur Pankhoriya');
    });

    testWidgets('a server validation error is shown against the field', (
      tester,
    ) async {
      final temple = FakeTempleRepository()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'map_url': ['The map url field must be a valid URL.'],
          },
        );

      await pumpTemple(tester, const AdminTempleProfileScreen(), temple);

      await tester.tap(find.byKey(const Key('temple-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('temple-error')), findsOneWidget);
      expect(
        find.text('The map url field must be a valid URL.'),
        findsOneWidget,
      );
    });

    testWidgets('a forbidden load shows the unauthorized state', (
      tester,
    ) async {
      final temple = FakeTempleRepository(
        adminError: const AppException(code: ErrorCode.forbidden),
      );

      await pumpTemple(tester, const AdminTempleProfileScreen(), temple);

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
    });

    testWidgets('without temple.manage the form is read-only', (tester) async {
      // The save control is hidden as a courtesy; the server refuses the write
      // regardless, which TempleAuthorizationTest proves by calling it directly.
      await pumpTemple(
        tester,
        const AdminTempleProfileScreen(),
        FakeTempleRepository(),
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('temple-read-only')), findsOneWidget);
      expect(find.byKey(const Key('temple-save')), findsNothing);
    });
  });

  group('AdminCommitteeScreen', () {
    testWidgets('lists every member, published or not', (tester) async {
      final temple = FakeTempleRepository()
        ..adminMembers = [
          testAdminMember(id: 1, nameHi: 'राम प्रसाद', isPublished: true),
          testAdminMember(id: 2, nameHi: 'सीता देवी'),
        ];

      await pumpTemple(tester, const AdminCommitteeScreen(), temple);

      expect(find.text('राम प्रसाद'), findsOneWidget);
      expect(find.text('सीता देवी'), findsOneWidget);
      expect(find.byKey(const Key('committee-member-1')), findsOneWidget);
      expect(find.byKey(const Key('committee-member-2')), findsOneWidget);
      // Both states are labelled, so the list says which is which.
      expect(find.text('प्रकाशित'), findsOneWidget);
      expect(find.text('अप्रकाशित'), findsOneWidget);
    });

    testWidgets('flags a member whose personal details are public', (
      tester,
    ) async {
      // The one thing worth spotting without opening the record.
      final temple = FakeTempleRepository()
        ..adminMembers = [
          testAdminMember(
            id: 1,
            isPublished: true,
            hasConsent: true,
            showPhone: true,
          ),
          testAdminMember(id: 2, nameHi: 'निजी', isPublished: true),
        ];

      await pumpTemple(tester, const AdminCommitteeScreen(), temple);

      expect(
        find.byKey(const Key('committee-public-details-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('committee-public-details-2')), findsNothing);
    });

    testWidgets('an empty committee shows the empty state', (tester) async {
      await pumpTemple(
        tester,
        const AdminCommitteeScreen(),
        FakeTempleRepository(),
      );

      expect(find.byKey(const Key('committee-empty')), findsOneWidget);
    });

    testWidgets('without temple.manage the add button is not offered', (
      tester,
    ) async {
      await pumpTemple(
        tester,
        const AdminCommitteeScreen(),
        FakeTempleRepository(),
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('committee-new')), findsNothing);
    });

    testWidgets('a forbidden load shows the unauthorized state', (
      tester,
    ) async {
      final temple = FakeTempleRepository(
        adminError: const AppException(code: ErrorCode.forbidden),
      );

      await pumpTemple(tester, const AdminCommitteeScreen(), temple);

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
    });
  });
}
