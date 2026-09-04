import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/admin/data/admin_repository.dart';
import 'package:rkt_web/features/admin/domain/admin_models.dart';
import 'package:rkt_web/features/auth/domain/auth_user.dart';

/// Scriptable stand-in for the HTTP admin repository.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    List<AdminUser>? userList,
    List<ManagedRole>? roleList,
    PermissionCatalogue? catalogue,
    List<LoginAttempt>? history,
    this.usersError,
    this.rolesError,
    this.catalogueError,
    this.historyError,
    this.saveError,
    this.delay = Duration.zero,
  }) : userList = userList ?? [],
       roleList = roleList ?? [],
       catalogue = catalogue ?? testCatalogue(),
       history = history ?? [];

  List<AdminUser> userList;
  List<ManagedRole> roleList;
  PermissionCatalogue catalogue;
  List<LoginAttempt> history;

  AppException? usersError;
  AppException? rolesError;
  AppException? catalogueError;
  AppException? historyError;
  AppException? saveError;
  Duration delay;

  int createCalls = 0;
  int updateCalls = 0;
  int resetCalls = 0;
  int permissionSaveCalls = 0;
  AdminUserDraft? lastDraft;
  Set<String>? lastPermissions;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<AdminUser>> users({
    String? search,
    String? role,
    String? status,
  }) async {
    await _wait();
    if (usersError != null) throw usersError!;
    return userList;
  }

  @override
  Future<AdminUser> user(int id) async {
    await _wait();
    if (usersError != null) throw usersError!;
    return userList.firstWhere(
      (u) => u.id == id,
      orElse: () => throw const AppException(code: ErrorCode.notFound),
    );
  }

  @override
  Future<AdminUser> createUser(AdminUserDraft draft) async {
    createCalls++;
    lastDraft = draft;
    await _wait();
    if (saveError != null) throw saveError!;
    return testAdminUser(id: 99, email: draft.email);
  }

  @override
  Future<AdminUser> updateUser(int id, AdminUserDraft draft) async {
    updateCalls++;
    lastDraft = draft;
    await _wait();
    if (saveError != null) throw saveError!;
    return testAdminUser(id: id, email: draft.email);
  }

  @override
  Future<void> sendPasswordReset(int id) async {
    resetCalls++;
    await _wait();
    if (saveError != null) throw saveError!;
  }

  @override
  Future<List<LoginAttempt>> loginHistory(int id) async {
    await _wait();
    if (historyError != null) throw historyError!;
    return history;
  }

  @override
  Future<List<ManagedRole>> roles() async {
    await _wait();
    if (rolesError != null) throw rolesError!;
    return roleList;
  }

  @override
  Future<PermissionCatalogue> permissionCatalogue() async {
    await _wait();
    if (catalogueError != null) throw catalogueError!;
    return catalogue;
  }

  @override
  Future<ManagedRole> updateRolePermissions(
    int id,
    Set<String> permissions,
  ) async {
    permissionSaveCalls++;
    lastPermissions = permissions;
    await _wait();
    if (saveError != null) throw saveError!;

    final existing = roleList.firstWhere((r) => r.id == id);
    return ManagedRole(
      id: existing.id,
      slug: existing.slug,
      name: existing.name,
      permissions: permissions,
      isEditable: existing.isEditable,
    );
  }
}

AdminUser testAdminUser({
  int id = 1,
  String firstName = 'सीता',
  String? lastName = 'देवी',
  String email = 'sita@thakurbari.test',
  AccountStatus status = AccountStatus.active,
  String roleSlug = UserRole.contentManager,
  String roleName = 'Content Manager',
  DateTime? lastLoginAt,
}) {
  return AdminUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: lastName == null ? firstName : '$firstName $lastName',
    email: email,
    status: status,
    role: UserRole(id: 4, slug: roleSlug, name: roleName),
    lastLoginAt: lastLoginAt,
  );
}

ManagedRole testRole({
  int id = 5,
  String slug = UserRole.viewer,
  String name = 'Viewer',
  Set<String> permissions = const {Permissions.contentView},
  bool isEditable = true,
  int? userCount = 2,
}) {
  return ManagedRole(
    id: id,
    slug: slug,
    name: name,
    description: 'Read-only access to permitted modules.',
    permissions: permissions,
    isEditable: isEditable,
    userCount: userCount,
  );
}

/// A catalogue with one delivered module and one reserved for a later phase.
PermissionCatalogue testCatalogue() => const PermissionCatalogue([
  PermissionModule(
    module: 'content',
    label: 'Website content',
    phase: 1,
    permissions: [
      PermissionOption(key: Permissions.contentView, label: 'View pages'),
      PermissionOption(key: Permissions.contentManage, label: 'Edit pages'),
    ],
  ),
  PermissionModule(
    module: 'donations',
    label: 'Donations',
    phase: 6,
    permissions: [
      PermissionOption(key: Permissions.donationsView, label: 'View donations'),
    ],
  ),
]);

LoginAttempt testAttempt({
  int id = 1,
  bool successful = true,
  String ip = '127.0.0.1',
  DateTime? at,
}) {
  return LoginAttempt(
    id: id,
    email: 'sita@thakurbari.test',
    outcome: successful ? 'success' : 'invalid_credentials',
    successful: successful,
    ipAddress: ip,
    at: at ?? DateTime(2026, 9, 6, 10, 30),
  );
}
