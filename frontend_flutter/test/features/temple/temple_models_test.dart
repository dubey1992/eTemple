import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/features/temple/domain/committee_member.dart';
import 'package:rkt_web/features/temple/domain/temple_profile.dart';

void main() {
  group('TempleAddress', () {
    test('builds address lines in order, skipping blanks', () {
      final address = TempleAddress.fromJson({
        'village': 'Amarpur Pankhoriya',
        'panchayat': 'Kurma',
        'police_station': 'Rasulpur Ekchari',
        'district': 'Bhagalpur',
        'state': 'Bihar',
        'postal_code': '813204',
        'country': 'India',
        'address_line1': '   ',
      });

      expect(address.lines(panchayatLabel: 'पंचायत'), [
        'Amarpur Pankhoriya, पंचायत: Kurma',
        'Rasulpur Ekchari, Bhagalpur, Bihar, 813204',
        'India',
      ]);
      expect(address.isEmpty, isFalse);
    });

    test(
      'the panchayat label follows the caller, not a hardcoded language',
      () {
        final address = TempleAddress.fromJson({
          'village': 'Amarpur Pankhoriya',
          'panchayat': 'Kurma',
        });

        expect(
          address.lines(panchayatLabel: 'Panchayat').first,
          'Amarpur Pankhoriya, Panchayat: Kurma',
        );
      },
    );

    test('an unfilled address is empty', () {
      expect(TempleAddress.fromJson(null).isEmpty, isTrue);
      expect(TempleAddress.fromJson({'village': '  '}).isEmpty, isTrue);
      expect(
        TempleAddress.fromJson(null).lines(panchayatLabel: 'पंचायत'),
        isEmpty,
      );
    });

    test('the locality is the village and panchayat only', () {
      final address = TempleAddress.fromJson({
        'village': 'Amarpur Pankhoriya',
        'panchayat': 'Kurma',
        'district': 'Bhagalpur',
      });

      expect(address.locality, 'Amarpur Pankhoriya, Kurma');
      expect(
        TempleAddress.fromJson({'district': 'Bhagalpur'}).locality,
        isNull,
      );
    });
  });

  group('TempleProfile', () {
    test('parses the localized blocks and the address', () {
      final profile = TempleProfile.fromJson({
        'requested_language': 'en',
        'name': {
          'value': 'Radha Krishna Thakurbari',
          'language': 'en',
          'fallback_used': false,
        },
        'history': {
          'value': 'A history.',
          'language': 'en',
          'fallback_used': false,
        },
        'mission': {'value': null, 'language': 'hi', 'fallback_used': false},
        'address': {'village': 'Amarpur Pankhoriya'},
        'logo_url': 'https://cdn.example.test/logo.png',
        'established_year': 1965,
      });

      expect(profile.name.value, 'Radha Krishna Thakurbari');
      expect(profile.hasName, isTrue);
      expect(profile.history.value, 'A history.');
      expect(profile.mission.isEmpty, isTrue);
      expect(profile.address.village, 'Amarpur Pankhoriya');
      expect(profile.logoUrl, 'https://cdn.example.test/logo.png');
      expect(profile.establishedYear, 1965);
    });

    test('reports the Hindi fallback so the UI can say so', () {
      final profile = TempleProfile.fromJson({
        'name': {
          'value': 'राधा कृष्ण ठाकुरबाड़ी',
          'language': 'hi',
          'fallback_used': true,
        },
      });

      expect(profile.name.fallbackUsed, isTrue);
      expect(profile.name.language, 'hi');
    });

    test('an unconfigured profile parses without crashing', () {
      final profile = TempleProfile.fromJson(const {});

      expect(profile.hasName, isFalse);
      expect(profile.address.isEmpty, isTrue);
      expect(profile.logoUrl, isNull);
      expect(profile.establishedYear, isNull);
    });

    test('a blank logo url counts as absent', () {
      expect(TempleProfile.fromJson({'logo_url': '   '}).logoUrl, isNull);
    });
  });

  group('EditableTempleProfile and its draft', () {
    test('reads every editable field, numbers included', () {
      final editable = EditableTempleProfile.fromJson({
        'name_hi': 'राधा कृष्ण ठाकुरबाड़ी',
        'name_en': null,
        'established_year': 1965,
      });

      expect(editable['name_hi'], 'राधा कृष्ण ठाकुरबाड़ी');
      expect(editable['name_en'], '');
      expect(editable['established_year'], '1965');
      // Every field is present so the form can build a controller for each.
      expect(editable.values.keys, containsAll(EditableTempleProfile.fields));
    });

    test('sends blank fields as null, not empty strings', () {
      // Absent is what the public empty states key on; an empty string would
      // render as a blank line instead.
      final json = const TempleProfileDraft({
        'name_hi': ' राधा कृष्ण ठाकुरबाड़ी ',
        'name_en': '   ',
        'village': '',
      }).toJson();

      expect(json['name_hi'], 'राधा कृष्ण ठाकुरबाड़ी');
      expect(json['name_en'], isNull);
      expect(json['village'], isNull);
    });

    test('the established year is sent as a number', () {
      final json = const TempleProfileDraft({'established_year': '1965'})
          .toJson();

      expect(json['established_year'], 1965);
    });

    test('a non-numeric year is sent as null rather than as text', () {
      final json = const TempleProfileDraft({'established_year': 'not a year'})
          .toJson();

      expect(json['established_year'], isNull);
    });
  });

  group('CommitteeMember', () {
    test('personal details are absent unless the server sent them', () {
      // The API omits the key entirely when consent is not on record, so the
      // client has no decision to make and no value to leak.
      final member = CommitteeMember.fromJson({
        'id': 4,
        'name': {
          'value': 'राम प्रसाद',
          'language': 'hi',
          'fallback_used': false,
        },
        'designation': {
          'value': 'सचिव',
          'language': 'hi',
          'fallback_used': false,
        },
      });

      expect(member.id, 4);
      expect(member.phone, isNull);
      expect(member.email, isNull);
      expect(member.photoUrl, isNull);
      expect(member.hasPublicContact, isFalse);
    });

    test('reads the details the server did send', () {
      final member = CommitteeMember.fromJson({
        'id': 1,
        'phone': '+91 90000 00000',
        'email': 'president@example.test',
        'photo_url': 'https://cdn.example.test/p.jpg',
        'tenure_start': '2024-04-01',
      });

      expect(member.phone, '+91 90000 00000');
      expect(member.email, 'president@example.test');
      expect(member.photoUrl, 'https://cdn.example.test/p.jpg');
      expect(member.tenureStart, '2024-04-01');
      expect(member.hasPublicContact, isTrue);
    });
  });

  group('AdminCommitteeMember', () {
    test('reads the consent record and the visibility flags', () {
      final member = AdminCommitteeMember.fromJson({
        'id': 2,
        'name_hi': 'राम प्रसाद',
        'designation_hi': 'सचिव',
        'phone': '+91 90000 00000',
        'is_published': true,
        'has_consent': true,
        'contact_consent_at': '2026-06-01T10:30:00+05:30',
        'show_phone_publicly': true,
        'show_email_publicly': false,
        'tenure_has_ended': false,
      });

      expect(member.hasConsent, isTrue);
      expect(member.showPhonePublicly, isTrue);
      expect(member.showEmailPublicly, isFalse);
      expect(member.publishesPersonalDetails, isTrue);
      expect(member.hasPersonalDetailsOnFile, isTrue);
    });

    test('a flag set without consent does not count as published detail', () {
      // Defence in depth: even if the server ever sent this contradiction, the
      // list must not tell the committee the detail is public.
      final member = AdminCommitteeMember.fromJson({
        'id': 3,
        'name_hi': 'सदस्य',
        'designation_hi': 'सदस्य',
        'is_published': true,
        'has_consent': false,
        'show_phone_publicly': true,
      });

      expect(member.publishesPersonalDetails, isFalse);
    });

    test('an unpublished member publishes nothing however consented', () {
      final member = AdminCommitteeMember.fromJson({
        'id': 3,
        'name_hi': 'सदस्य',
        'designation_hi': 'सदस्य',
        'is_published': false,
        'has_consent': true,
        'show_phone_publicly': true,
      });

      expect(member.publishesPersonalDetails, isFalse);
    });
  });

  group('CommitteeMemberDraft', () {
    test('sends consent and the visibility flags together', () {
      // One decision, evaluated as a whole by the server.
      final json = const CommitteeMemberDraft(
        nameHi: ' राम प्रसाद ',
        designationHi: 'सचिव',
        nameEn: '  ',
        phone: '+91 90000 00000',
        isPublished: true,
        hasConsent: true,
        showPhonePublicly: true,
        showEmailPublicly: false,
        showPhotoPublicly: false,
      ).toJson();

      expect(json['name_hi'], 'राम प्रसाद');
      expect(json['name_en'], isNull);
      expect(json['has_consent'], true);
      expect(json['show_phone_publicly'], true);
      expect(json['show_email_publicly'], false);
      expect(json['show_photo_publicly'], false);
      expect(json['is_published'], true);
    });

    test('blank optional fields are sent as null', () {
      final json = const CommitteeMemberDraft(
        nameHi: 'सदस्य',
        designationHi: 'सदस्य',
        phone: '   ',
        tenureEnd: '',
        isPublished: false,
        hasConsent: false,
        showPhonePublicly: false,
        showEmailPublicly: false,
        showPhotoPublicly: false,
      ).toJson();

      expect(json['phone'], isNull);
      expect(json['tenure_end'], isNull);
    });
  });
}
