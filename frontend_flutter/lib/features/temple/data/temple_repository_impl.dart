import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/committee_member.dart';
import '../domain/temple_profile.dart';
import '../domain/temple_repository.dart';

/// HTTP implementation of [TempleRepository] against the Laravel API.
class TempleRepositoryImpl implements TempleRepository {
  const TempleRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<TempleProfile> profile({required String language}) async {
    final envelope = await _api.get<TempleProfile>(
      ApiEndpoints.publicTempleProfile,
      queryParameters: {'lang': language},
      decode: (data) => TempleProfile.fromJson(_object(data, 'temple profile')),
    );
    return envelope.data;
  }

  @override
  Future<List<CommitteeMember>> committee({required String language}) async {
    final envelope = await _api.get<List<CommitteeMember>>(
      ApiEndpoints.publicCommittee,
      queryParameters: {'lang': language},
      decode: (data) => _list(
        data,
        'committee members',
      ).map(CommitteeMember.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<EditableTempleProfile> adminProfile() async {
    final envelope = await _api.get<EditableTempleProfile>(
      ApiEndpoints.adminTempleProfile,
      decode: (data) =>
          EditableTempleProfile.fromJson(_object(data, 'temple profile')),
    );
    return envelope.data;
  }

  @override
  Future<EditableTempleProfile> saveProfile(TempleProfileDraft draft) async {
    final envelope = await _api.put<EditableTempleProfile>(
      ApiEndpoints.adminTempleProfile,
      body: draft.toJson(),
      decode: (data) =>
          EditableTempleProfile.fromJson(_object(data, 'temple profile')),
    );
    return envelope.data;
  }

  @override
  Future<List<AdminCommitteeMember>> adminCommittee() async {
    final envelope = await _api.get<List<AdminCommitteeMember>>(
      ApiEndpoints.adminCommitteeMembers,
      decode: (data) => _list(
        data,
        'committee members',
      ).map(AdminCommitteeMember.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<AdminCommitteeMember> adminMember(int id) async {
    final envelope = await _api.get<AdminCommitteeMember>(
      ApiEndpoints.adminCommitteeMember(id),
      decode: (data) =>
          AdminCommitteeMember.fromJson(_object(data, 'committee member')),
    );
    return envelope.data;
  }

  @override
  Future<AdminCommitteeMember> createMember(CommitteeMemberDraft draft) async {
    final envelope = await _api.post<AdminCommitteeMember>(
      ApiEndpoints.adminCommitteeMembers,
      body: draft.toJson(),
      decode: (data) =>
          AdminCommitteeMember.fromJson(_object(data, 'committee member')),
    );
    return envelope.data;
  }

  @override
  Future<AdminCommitteeMember> saveMember(
    int id,
    CommitteeMemberDraft draft,
  ) async {
    final envelope = await _api.put<AdminCommitteeMember>(
      ApiEndpoints.adminCommitteeMember(id),
      body: draft.toJson(),
      decode: (data) =>
          AdminCommitteeMember.fromJson(_object(data, 'committee member')),
    );
    return envelope.data;
  }

  @override
  Future<void> deleteMember(int id) async {
    await _api.delete<void>(
      ApiEndpoints.adminCommitteeMember(id),
      decode: (_) {},
    );
  }

  static List<Map<String, dynamic>> _list(Object? data, String what) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }
    return data
        .map(ApiEnvelopeParser.asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic> _object(Object? data, String what) {
    final json = ApiEnvelopeParser.asMap(data);
    if (json == null) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a $what object in the response data.',
      );
    }
    return json;
  }
}
