import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/enquiries/domain/enquiry.dart';
import 'package:rkt_web/features/enquiries/presentation/contact_screen.dart';

import '../../support/fake_enquiry_repository.dart';
import '../../support/pump_app.dart';

void main() {
  Future<void> fill(
    WidgetTester tester, {
    String name = 'रामप्रसाद यादव',
    String mobile = '9876500011',
    String email = '',
    String message = 'क्या अगले रविवार को सत्यनारायण पूजा कराई जा सकती है?',
  }) async {
    await tester.enterText(find.byKey(const Key('enquiry-name')), name);
    await tester.enterText(find.byKey(const Key('enquiry-mobile')), mobile);
    await tester.enterText(find.byKey(const Key('enquiry-email')), email);
    await tester.enterText(find.byKey(const Key('enquiry-message')), message);
    await tester.pump();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('enquiry-submit')));
    await tester.tap(find.byKey(const Key('enquiry-submit')));
    await tester.pumpAndSettle();
  }

  group('ContactScreen', () {
    testWidgets('shows the address and the form together', (tester) async {
      final repository = FakeEnquiryRepository();

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contact-form')), findsOneWidget);
      // The ticket is fetched when the page opens, not when send is pressed:
      // the server measures how long the form was open.
      expect(repository.formCalls, 1);
    });

    testWidgets('sends what the visitor typed', (tester) async {
      final repository = FakeEnquiryRepository();

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      await fill(tester);
      await send(tester);

      final draft = repository.lastDraft!;
      expect(draft.name, 'रामप्रसाद यादव');
      expect(draft.mobile, '9876500011');
      expect(draft.email, isNull);
      expect(draft.formToken, 'test-token');

      // The honeypot travels on every submission and is always empty: a field
      // that appeared only when filled would be trivial for a script to spot.
      expect(draft.toJson()['website'], '');
    });

    testWidgets('shows the reference it was given', (tester) async {
      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: FakeEnquiryRepository(
          receipt: const EnquiryReceipt(
            reference: 'RKT/E/2026-27/0042',
            message: 'received',
          ),
        ),
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      await fill(tester);
      await send(tester);

      expect(find.byKey(const Key('contact-sent')), findsOneWidget);
      expect(find.textContaining('RKT/E/2026-27/0042'), findsOneWidget);
      expect(find.byKey(const Key('contact-form')), findsNothing);
    });

    testWidgets('a dropped submission looks exactly like a sent one', (
      tester,
    ) async {
      // What the server answers for a honeypot hit: the success shape, with no
      // reference. The visitor is never told the difference.
      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: FakeEnquiryRepository(
          receipt: const EnquiryReceipt(reference: null, message: 'received'),
        ),
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      await fill(tester);
      await send(tester);

      expect(find.byKey(const Key('contact-sent')), findsOneWidget);
      expect(find.textContaining('RKT/E'), findsNothing);
    });

    testWidgets('refuses to send with no way to reply', (tester) async {
      final repository = FakeEnquiryRepository();

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      await fill(tester, mobile: '', email: '');
      await send(tester);

      // Never reached the network: the same rule is enforced again on the
      // server, but there is no reason to spend a ticket finding out.
      expect(repository.submitCalls, 0);
      expect(find.byKey(const Key('enquiry-error')), findsOneWidget);
    });

    testWidgets('a message that is too short is refused before sending', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository();

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      await fill(tester, message: 'बहुत छोटा');
      await send(tester);

      expect(repository.submitCalls, 0);
    });

    testWidgets('an expired ticket keeps the message and fetches a new one', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(
        submitError: const AppException(code: ErrorCode.enquiryFormExpired),
      );

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      await fill(tester);
      await send(tester);

      // Losing somebody's message to an anti-spam measure would be a worse
      // failure than the spam: every word is still on screen.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('enquiry-message')),
                matching: find.byType(TextField),
              ),
            )
            .controller
            ?.text,
        contains('सत्यनारायण'),
      );
      expect(find.byKey(const Key('enquiry-error')), findsOneWidget);
      expect(repository.formCalls, greaterThan(1));
    });

    testWidgets('the question appears only when the server asks one', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: FakeEnquiryRepository(),
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('enquiry-challenge-answer')), findsNothing);
    });

    testWidgets('the answer to the question is sent with the message', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(
        form: testEnquiryForm(
          challenge: const EnquiryChallenge(
            questionHi: 'सात और तीन को जोड़ने पर कितना होता है?',
            questionEn: 'What is seven plus three?',
          ),
        ),
      );

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2400),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('सात और तीन को जोड़ने पर कितना होता है?'),
        findsOneWidget,
      );

      await fill(tester);
      await tester.enterText(
        find.byKey(const Key('enquiry-challenge-answer')),
        '10',
      );
      await send(tester);

      expect(repository.lastDraft?.challengeAnswer, '10');
    });

    testWidgets('an unreachable form is an error with a retry, not a blank', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(
        formError: const AppException(code: ErrorCode.network),
      );

      await pumpScreen(
        tester,
        const ContactScreen(),
        enquiries: repository,
        surfaceSize: const Size(1200, 2200),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contact-form')), findsNothing);
      // The address above it is unaffected — which is what most visitors came
      // for in the first place.
      expect(find.byKey(const Key('address-card')), findsOneWidget);
    });
  });
}
