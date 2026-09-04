import '../../content/domain/localized_value.dart';

/// A committee member as the public site sees them.
///
/// [phone], [email] and [photoUrl] are null whenever the server withheld them.
/// The API omits the key entirely unless the member's consent is on record, so
/// "null" here means "not published", never "not known" — the client cannot
/// reveal a detail the server declined to send.
class CommitteeMember {
  const CommitteeMember({
    required this.id,
    required this.name,
    required this.designation,
    required this.bio,
    this.tenureStart,
    this.tenureEnd,
    this.phone,
    this.email,
    this.photoUrl,
  });

  factory CommitteeMember.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return CommitteeMember(
      id: _asInt(json['id']) ?? 0,
      name: LocalizedValue.fromJson(json['name']),
      designation: LocalizedValue.fromJson(json['designation']),
      bio: LocalizedValue.fromJson(json['bio']),
      tenureStart: read('tenure_start'),
      tenureEnd: read('tenure_end'),
      phone: read('phone'),
      email: read('email'),
      photoUrl: read('photo_url'),
    );
  }

  final int id;
  final LocalizedValue name;
  final LocalizedValue designation;
  final LocalizedValue bio;
  final String? tenureStart;
  final String? tenureEnd;
  final String? phone;
  final String? email;
  final String? photoUrl;

  bool get hasPublicContact => phone != null || email != null;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// A committee member as the editor sees them: both languages raw, every
/// personal detail present, and the consent record shown explicitly.
///
/// Consent governs *publication*, not administration — an editor deciding
/// whether to publish a phone number has to be able to see it.
class AdminCommitteeMember {
  const AdminCommitteeMember({
    required this.id,
    required this.nameHi,
    required this.designationHi,
    required this.isPublished,
    required this.hasConsent,
    required this.showPhonePublicly,
    required this.showEmailPublicly,
    required this.showPhotoPublicly,
    required this.tenureHasEnded,
    required this.sortOrder,
    this.nameEn,
    this.designationEn,
    this.bioHi,
    this.bioEn,
    this.phone,
    this.email,
    this.photoUrl,
    this.tenureStart,
    this.tenureEnd,
    this.consentRecordedAt,
  });

  factory AdminCommitteeMember.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    bool flag(String key) => json[key] == true;

    return AdminCommitteeMember(
      id: CommitteeMember._asInt(json['id']) ?? 0,
      nameHi: read('name_hi') ?? '',
      nameEn: read('name_en'),
      designationHi: read('designation_hi') ?? '',
      designationEn: read('designation_en'),
      bioHi: read('bio_hi'),
      bioEn: read('bio_en'),
      phone: read('phone'),
      email: read('email'),
      photoUrl: read('photo_url'),
      tenureStart: read('tenure_start'),
      tenureEnd: read('tenure_end'),
      tenureHasEnded: flag('tenure_has_ended'),
      isPublished: flag('is_published'),
      hasConsent: flag('has_consent'),
      consentRecordedAt: read('contact_consent_at'),
      showPhonePublicly: flag('show_phone_publicly'),
      showEmailPublicly: flag('show_email_publicly'),
      showPhotoPublicly: flag('show_photo_publicly'),
      sortOrder: CommitteeMember._asInt(json['sort_order']) ?? 0,
    );
  }

  final int id;
  final String nameHi;
  final String? nameEn;
  final String designationHi;
  final String? designationEn;
  final String? bioHi;
  final String? bioEn;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? tenureStart;
  final String? tenureEnd;
  final bool tenureHasEnded;
  final bool isPublished;
  final bool hasConsent;
  final String? consentRecordedAt;
  final bool showPhonePublicly;
  final bool showEmailPublicly;
  final bool showPhotoPublicly;
  final int sortOrder;

  /// True when this member has a personal detail on file that is being shown
  /// publicly. Drives the "visible to everyone" warning on the list.
  bool get publishesPersonalDetails =>
      isPublished &&
      hasConsent &&
      (showPhonePublicly || showEmailPublicly || showPhotoPublicly);

  bool get hasPersonalDetailsOnFile =>
      phone != null || email != null || photoUrl != null;
}

/// The member an editor is submitting.
///
/// `hasConsent` and the three visibility flags are sent together so the server
/// evaluates them as one decision. The rule between them — nothing published
/// without recorded consent — is enforced server-side; this type only carries
/// the editor's intent.
class CommitteeMemberDraft {
  const CommitteeMemberDraft({
    required this.nameHi,
    required this.designationHi,
    required this.isPublished,
    required this.hasConsent,
    required this.showPhonePublicly,
    required this.showEmailPublicly,
    required this.showPhotoPublicly,
    this.nameEn,
    this.designationEn,
    this.bioHi,
    this.bioEn,
    this.phone,
    this.email,
    this.photoUrl,
    this.tenureStart,
    this.tenureEnd,
    this.sortOrder = 0,
  });

  final String nameHi;
  final String? nameEn;
  final String designationHi;
  final String? designationEn;
  final String? bioHi;
  final String? bioEn;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? tenureStart;
  final String? tenureEnd;
  final bool isPublished;
  final bool hasConsent;
  final bool showPhonePublicly;
  final bool showEmailPublicly;
  final bool showPhotoPublicly;
  final int sortOrder;

  /// Blank optional fields are sent as null so the server stores "absent"
  /// rather than an empty string, which is what the fallback rule keys on.
  Map<String, Object?> toJson() => {
    'name_hi': nameHi.trim(),
    'name_en': _nullIfBlank(nameEn),
    'designation_hi': designationHi.trim(),
    'designation_en': _nullIfBlank(designationEn),
    'bio_hi': _nullIfBlank(bioHi),
    'bio_en': _nullIfBlank(bioEn),
    'phone': _nullIfBlank(phone),
    'email': _nullIfBlank(email),
    'photo_url': _nullIfBlank(photoUrl),
    'tenure_start': _nullIfBlank(tenureStart),
    'tenure_end': _nullIfBlank(tenureEnd),
    'is_published': isPublished,
    'has_consent': hasConsent,
    'show_phone_publicly': showPhonePublicly,
    'show_email_publicly': showEmailPublicly,
    'show_photo_publicly': showPhotoPublicly,
    'sort_order': sortOrder,
  };

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
