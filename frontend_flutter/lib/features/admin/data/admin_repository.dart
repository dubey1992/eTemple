import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/admin_models.dart';

/// Reading and changing committee accounts, roles and the permission matrix.
abstract interface class AdminRepository {
  Future<List<AdminUser>> users({String? search, String? role, String? status});

  Future<AdminUser> user(int id);

  Future<AdminUser> createUser(AdminUserDraft draft);

  Future<AdminUser> updateUser(int id, AdminUserDraft draft);

  Future<void> sendPasswordReset(int id);

  Future<List<LoginAttempt>> loginHistory(int id);

  Future<List<ManagedRole>> roles();

  Future<PermissionCatalogue> permissionCatalogue();

  /// Replaces a role's permission set. Throws for Super Admin, whose set is
  /// fixed on the server.
  Future<ManagedRole> updateRolePermissions(int id, Set<String> permissions);
}

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<AdminUser>> users({
    String? search,
    String? role,
    String? status,
  }) async {
    final envelope = await _api.get<List<AdminUser>>(
      ApiEndpoints.adminUsers,
      queryParameters: {
        'per_page': 100,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      decode: (data) => _list(data, AdminUser.fromJson, 'users'),
    );
    return envelope.data;
  }

  @override
  Future<AdminUser> user(int id) async {
    final envelope = await _api.get<AdminUser>(
      ApiEndpoints.adminUser(id),
      decode: (data) => AdminUser.fromJson(_object(data, 'user')),
    );
    return envelope.data;
  }

  @override
  Future<AdminUser> createUser(AdminUserDraft draft) async {
    final envelope = await _api.post<AdminUser>(
      ApiEndpoints.adminUsers,
      body: draft.toJson(),
      decode: (data) => AdminUser.fromJson(_object(data, 'user')),
    );
    return envelope.data;
  }

  @override
  Future<AdminUser> updateUser(int id, AdminUserDraft draft) async {
    final envelope = await _api.put<AdminUser>(
      ApiEndpoints.adminUser(id),
      body: draft.toJson(),
      decode: (data) => AdminUser.fromJson(_object(data, 'user')),
    );
    return envelope.data;
  }

  @override
  Future<void> sendPasswordReset(int id) async {
    await _api.post<void>(
      ApiEndpoints.adminUserPasswordReset(id),
      decode: (_) {},
    );
  }

  @override
  Future<List<LoginAttempt>> loginHistory(int id) async {
    final envelope = await _api.get<List<LoginAttempt>>(
      ApiEndpoints.adminUserLoginHistory(id),
      queryParameters: {'per_page': 50},
      decode: (data) => _list(data, LoginAttempt.fromJson, 'login attempts'),
    );
    return envelope.data;
  }

  @override
  Future<List<ManagedRole>> roles() async {
    final envelope = await _api.get<List<ManagedRole>>(
      ApiEndpoints.adminRoles,
      decode: (data) => _list(data, ManagedRole.fromJson, 'roles'),
    );
    return envelope.data;
  }

  @override
  Future<PermissionCatalogue> permissionCatalogue() async {
    final envelope = await _api.get<PermissionCatalogue>(
      ApiEndpoints.adminPermissions,
      decode: (data) =>
          PermissionCatalogue.fromJson(_object(data, 'permission catalogue')),
    );
    return envelope.data;
  }

  @override
  Future<ManagedRole> updateRolePermissions(
    int id,
    Set<String> permissions,
  ) async {
    final envelope = await _api.put<ManagedRole>(
      ApiEndpoints.adminRolePermissions(id),
      body: {'permissions': permissions.toList()},
      decode: (data) => ManagedRole.fromJson(_object(data, 'role')),
    );
    return envelope.data;
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

  static List<T> _list<T>(
    Object? data,
    T Function(Map<String, dynamic>) fromJson,
    String what,
  ) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }
    return data
        .map(ApiEnvelopeParser.asMap)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
