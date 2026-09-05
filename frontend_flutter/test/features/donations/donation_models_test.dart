import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/features/donations/domain/donation.dart';
import 'package:rkt_web/features/donations/domain/donation_repository.dart';
import 'package:rkt_web/features/donations/presentation/donation_formatting.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

void main() {
  group('Donation', () {
    test('reads the amount as paise and as the text a person sees', () {
      // The paise are the authority and the string is what is displayed.
      // Nothing on this side ever divides by a hundred, which is how a rupee
      // total stops being exact.
      final donation = Donation.fromJson({
        'id': 7,
        'receipt_number': 'RKT/2026-27/0004',
        'donor_name': 'रामप्रसाद यादव',
        'amount_paise': 12_550_000,
        'amount_formatted': '₹1,25,500.00',
        'donation_date': '2026-06-15',
        'payment_mode': 'upi',
        'reference_number': 'UPI-9931',
        'purpose': 'festival',
        'status': 'confirmed',
        'is_locked': true,
      });

      expect(donation.amountPaise, 12_550_000);
      expect(donation.amountFormatted, '₹1,25,500.00');
      expect(donation.isConfirmed, isTrue);
      expect(donation.isLocked, isTrue);
      expect(donation.needsReference, isTrue);
    });

    test('a pending donation has no receipt and is not locked', () {
      final donation = Donation.fromJson({
        'id': 1,
        'donor_name': 'सीता देवी',
        'amount_paise': 50_100,
        'status': 'pending',
      });

      expect(donation.receiptNumber, isNull);
      expect(donation.isPending, isTrue);
      expect(donation.isLocked, isFalse);
    });

    test('cash is the one mode that needs no reference', () {
      // Everything else leaves something the treasurer can match against a
      // statement, which is the whole point of verifying before receipting.
      expect(PaymentModes.requiresReference(PaymentModes.cash), isFalse);
      for (final mode in PaymentModes.all.where(
        (m) => m != PaymentModes.cash,
      )) {
        expect(
          PaymentModes.requiresReference(mode),
          isTrue,
          reason: '$mode should require a reference',
        );
      }
    });

    test('a malformed payload is an empty donation, not a crash', () {
      final donation = Donation.fromJson({});

      expect(donation.id, 0);
      expect(donation.donorName, '');
      expect(donation.amountPaise, 0);
      expect(donation.status, DonationStatuses.pending);
    });
  });

  group('DonationDraft', () {
    test('sends the amount as the string that was typed', () {
      // A double here would round ₹501.50 before the request was even sent.
      final json = const DonationDraft(
        donorName: '  रामप्रसाद  ',
        amount: ' 1,25,500 ',
        donationDate: '2026-06-15',
        paymentMode: PaymentModes.cash,
        purpose: DonationPurposes.general,
      ).toJson();

      expect(json['amount'], '1,25,500');
      expect(json['amount'], isA<String>());
      expect(json['donor_name'], 'रामप्रसाद');
    });

    test('sends blank optional fields as null', () {
      final json = const DonationDraft(
        donorName: 'सीता देवी',
        amount: '501',
        donationDate: '2026-06-15',
        paymentMode: PaymentModes.cash,
        purpose: DonationPurposes.general,
        donorPhone: '   ',
        notes: '',
      ).toJson();

      expect(json['donor_phone'], isNull);
      expect(json['notes'], isNull);
    });
  });

  group('DonationQuery', () {
    test('two identical queries are the same provider key', () {
      // Without value equality every rebuild would refetch the same page.
      expect(
        const DonationQuery(status: DonationStatuses.pending, page: 2),
        const DonationQuery(status: DonationStatuses.pending, page: 2),
      );
      expect(
        const DonationQuery(status: DonationStatuses.pending).hashCode,
        const DonationQuery(status: DonationStatuses.pending).hashCode,
      );
      expect(const DonationQuery(page: 1), isNot(const DonationQuery(page: 2)));
    });

    test('omits filters that were not asked for', () {
      final params = const DonationQuery().toQueryParameters();

      expect(params.containsKey('status'), isFalse);
      expect(params.containsKey('q'), isFalse);
      expect(params['page'], 1);
    });

    test('builds the query string the API expects', () {
      final params = const DonationQuery(
        status: DonationStatuses.confirmed,
        mode: PaymentModes.upi,
        from: '2026-04-01',
        search: 'सीता',
      ).toQueryParameters();

      expect(params['status'], DonationStatuses.confirmed);
      expect(params['mode'], PaymentModes.upi);
      expect(params['from'], '2026-04-01');
      expect(params['q'], 'सीता');
    });
  });

  group('DonationSummary', () {
    test('reads the totals the server computed', () {
      // Computed over every donation matching the filter, not over the page in
      // view — which is why the client only reads them.
      final summary = DonationSummary.fromJson({
        'total_paise': 12_550_000,
        'total_formatted': '₹1,25,500.00',
        'pending_paise': 50_000,
        'pending_formatted': '₹500.00',
        'confirmed_count': 12,
        'pending_count': 1,
        'reversed_count': 2,
        'donor_count': 126,
      });

      expect(summary.totalFormatted, '₹1,25,500.00');
      expect(summary.donorCount, 126);
      expect(summary.reversedCount, 2);
    });

    test('a missing summary is zeroes, not a crash', () {
      final summary = DonationSummary.fromJson({});

      expect(summary.totalPaise, 0);
      expect(summary.totalFormatted, '—');
    });
  });

  group('DonationDetails', () {
    test('lists only the rows the committee has filled in', () {
      // A plausible-looking blank is worse than an absent line: this is where
      // devotees' money goes.
      final details = DonationDetails.fromJson({
        'upi_id': 'thakurbari@upi',
        'bank_name': 'Demo Bank',
        'account_number': '  ',
        'ifsc': null,
      });

      final rows = details.rows(
        upiLabel: 'UPI',
        bankLabel: 'Bank',
        accountNameLabel: 'Name',
        accountLabel: 'A/C',
        ifscLabel: 'IFSC',
      );

      expect(rows.map((r) => r.$1), ['UPI', 'Bank']);
      expect(rows.first.$2, 'thakurbari@upi');
    });
  });

  group('DonationFormatting', () {
    late AppLocalizations hi;

    setUp(() async {
      hi = await AppLocalizations.delegate.load(AppLocales.hindi);
      // In the application `GlobalMaterialLocalizations` loads this for the
      // active locale. A pure unit test has no widget tree to do it, so it is
      // done here rather than pumping a screen to format a date.
      await initializeDateFormatting();
    });

    test('every payment mode the server can send has words', () {
      for (final mode in PaymentModes.all) {
        final label = DonationFormatting.modeLabel(mode, hi);
        expect(label, isNotEmpty, reason: '$mode has no label');
      }
    });

    test('every purpose the server can send has words', () {
      for (final purpose in DonationPurposes.all) {
        expect(
          DonationFormatting.purposeLabel(purpose, hi),
          isNotEmpty,
          reason: '$purpose has no label',
        );
      }
    });

    test('every status has words', () {
      for (final status in DonationStatuses.all) {
        expect(DonationFormatting.statusLabel(status, hi), isNotEmpty);
      }
    });

    test('a date is read as a day, not as an instant', () {
      // A donation happens on a day. Turning it into an instant is how Phase 4
      // lost an afternoon to a timezone.
      final formatted = DonationFormatting.date('2026-06-15', 'en');

      expect(formatted, contains('2026'));
      expect(formatted, contains('15'));
    });

    test('an unparseable date is shown as sent rather than swallowed', () {
      expect(DonationFormatting.date('not-a-date', 'en'), 'not-a-date');
    });

    test('a timestamp keeps the temple clock the server sent', () {
      // Same rule as the calendar: the offset is dropped and the wall clock
      // kept, so the time does not move with the reader.
      final formatted = DonationFormatting.timestamp(
        '2026-06-20T18:30:00+05:30',
        'en',
      );

      expect(formatted, contains('6:30'));
    });
  });
}
