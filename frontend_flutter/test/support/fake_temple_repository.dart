import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/temple/domain/committee_member.dart';
import 'package:rkt_web/features/temple/domain/temple_profile.dart';
import 'package:rkt_web/features/temple/domain/temple_repository.dart';

/// Scriptable stand-in for the HTTP temple repository.
///
/// Widget tests use this so nothing touches a network and every state — loaded,
/// empty, forbidden, offline — is reproducible.
class FakeTempleRepository implements TempleRepository {
  FakeTempleRepository({
    TempleProfile? profile,
    List<CommitteeMember>? members,
    this.profileError,
    this.committeeError,
    this.adminError,
    this.saveError,
    this.delay = Duration.zero,
  }) : templeProfile = profile ?? TempleProfile.empty,
       members = members ?? const [];

  /// Named to avoid colliding with the interface's `profile()` method.
  TempleProfile templeProfile;
  List<CommitteeMember> members;

  AppException? profileError;
  AppException? committeeError;
  AppException? adminError;
  AppException? saveError;
  Duration delay;

  EditableTempleProfile editableProfile = const EditableTempleProfile();
  List<AdminCommitteeMember> adminMembers = [];

  int profileCalls = 0;
  int committeeCalls = 0;
  int saveProfileCalls = 0;
  int createMemberCalls = 0;
  int saveMemberCalls = 0;
  int deleteMemberCalls = 0;

  TempleProfileDraft? lastProfileDraft;
  CommitteeMemberDraft? lastMemberDraft;
  int? lastDeletedId;
  String? lastLanguage;

  Future<void> _pause() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<TempleProfile> profile({required String language}) async {
    profileCalls++;
    lastLanguage = language;
    await _pause();
    if (profileError != null) throw profileError!;
    return templeProfile;
  }

  @override
  Future<List<CommitteeMember>> committee({required String language}) async {
    committeeCalls++;
    lastLanguage = language;
    await _pause();
    if (committeeError != null) throw committeeError!;
    return members;
  }

  @override
  Future<EditableTempleProfile> adminProfile() async {
    await _pause();
    if (adminError != null) throw adminError!;
    return editableProfile;
  }

  @override
  Future<EditableTempleProfile> saveProfile(TempleProfileDraft draft) async {
    saveProfileCalls++;
    lastProfileDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return editableProfile;
  }

  @override
  Future<List<AdminCommitteeMember>> adminCommittee() async {
    await _pause();
    if (adminError != null) throw adminError!;
    return adminMembers;
  }

  @override
  Future<AdminCommitteeMember> adminMember(int id) async {
    await _pause();
    if (adminError != null) throw adminError!;
    return adminMembers.firstWhere(
      (m) => m.id == id,
      orElse: () => throw const AppException(code: ErrorCode.notFound),
    );
  }

  @override
  Future<AdminCommitteeMember> createMember(CommitteeMemberDraft draft) async {
    createMemberCalls++;
    lastMemberDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminMember(id: 99, nameHi: draft.nameHi);
  }

  @override
  Future<AdminCommitteeMember> saveMember(
    int id,
    CommitteeMemberDraft draft,
  ) async {
    saveMemberCalls++;
    lastMemberDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminMember(id: id, nameHi: draft.nameHi);
  }

  @override
  Future<void> deleteMember(int id) async {
    deleteMemberCalls++;
    lastDeletedId = id;
    await _pause();
    if (saveError != null) throw saveError!;
  }
}

LocalizedValue _hi(String? value) =>
    LocalizedValue(value: value, language: 'hi', fallbackUsed: false);

/// A public committee member for widget tests.
///
/// Personal details default to absent — which is what the API sends when
/// consent is not on record, so a test has to opt in to them the same way the
/// committee does.
CommitteeMember testMember({
  int id = 1,
  String name = 'परीक्षण सदस्य',
  String designation = 'अध्यक्ष',
  String? bio,
  String? tenureStart,
  String? tenureEnd,
  String? phone,
  String? email,
  String? photoUrl,
  bool fallbackUsed = false,
}) {
  return CommitteeMember(
    id: id,
    name: LocalizedValue(
      value: name,
      language: fallbackUsed ? 'hi' : 'hi',
      fallbackUsed: fallbackUsed,
    ),
    designation: _hi(designation),
    bio: _hi(bio),
    tenureStart: tenureStart,
    tenureEnd: tenureEnd,
    phone: phone,
    email: email,
    photoUrl: photoUrl,
  );
}

/// A member as the editor sees them.
AdminCommitteeMember testAdminMember({
  int id = 1,
  String nameHi = 'परीक्षण सदस्य',
  String designationHi = 'अध्यक्ष',
  String? phone,
  String? email,
  String? photoUrl,
  bool isPublished = false,
  bool hasConsent = false,
  bool showPhone = false,
  bool showEmail = false,
  bool showPhoto = false,
  bool tenureHasEnded = false,
  String? consentRecordedAt,
  int sortOrder = 0,
}) {
  return AdminCommitteeMember(
    id: id,
    nameHi: nameHi,
    designationHi: designationHi,
    phone: phone,
    email: email,
    photoUrl: photoUrl,
    isPublished: isPublished,
    hasConsent: hasConsent,
    showPhonePublicly: showPhone,
    showEmailPublicly: showEmail,
    showPhotoPublicly: showPhoto,
    tenureHasEnded: tenureHasEnded,
    consentRecordedAt: consentRecordedAt,
    sortOrder: sortOrder,
  );
}

/// A configured temple profile for widget tests.
TempleProfile testProfile({
  String? name = 'राधा कृष्ण ठाकुरबाड़ी',
  String? village = 'Amarpur Pankhoriya',
  String? panchayat = 'Kurma',
  String? history,
  String? mission = 'ग्रामवासियों की आस्था और सेवा का केंद्र।',
}) {
  return TempleProfile(
    requestedLanguage: 'hi',
    name: _hi(name),
    history: _hi(history),
    mission: _hi(mission),
    address: TempleAddress(village: village, panchayat: panchayat),
  );
}
