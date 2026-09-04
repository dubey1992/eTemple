import 'committee_member.dart';
import 'temple_profile.dart';

/// Contract for reading and editing the temple's own profile and its committee.
///
/// Implementations live in `data/` and are the only place that knows about HTTP.
abstract interface class TempleRepository {
  /// The temple's public identity, resolved for [language].
  Future<TempleProfile> profile({required String language});

  /// Published, currently-serving committee members, resolved for [language].
  ///
  /// Personal details are present only where the server judged consent to be on
  /// record; the client never decides that.
  Future<List<CommitteeMember>> committee({required String language});

  /// The profile with both languages raw, for the editor.
  Future<EditableTempleProfile> adminProfile();

  /// Saves the temple profile. Requires `temple.manage`.
  Future<EditableTempleProfile> saveProfile(TempleProfileDraft draft);

  /// Every committee member, including unpublished and past ones.
  Future<List<AdminCommitteeMember>> adminCommittee();

  /// One member loaded raw for editing.
  Future<AdminCommitteeMember> adminMember(int id);

  /// Creates a member. Requires `temple.manage`.
  Future<AdminCommitteeMember> createMember(CommitteeMemberDraft draft);

  /// Updates a member. Requires `temple.manage`.
  Future<AdminCommitteeMember> saveMember(int id, CommitteeMemberDraft draft);

  /// Permanently removes a member — erasure, not retirement. Ending a tenure is
  /// how somebody leaves the committee while the record is kept.
  Future<void> deleteMember(int id);
}
