import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/auth/domain/auth_repository.dart';
import 'package:rkt_web/features/auth/domain/auth_user.dart';

/// Scriptable stand-in for the HTTP repository.
///
/// Widget and controller tests use this so nothing touches a network and every
/// outcome (success, blocked account, network failure) is reproducible.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.session,
    this.signInResult,
    this.signInError,
    this.currentUserError,
    this.resetError,
    this.resetPasswordError,
    this.delay = Duration.zero,
  });

  /// User returned by [currentUser]; `null` means signed out.
  AuthUser? session;

  AuthUser? signInResult;
  AppException? signInError;
  AppException? currentUserError;
  AppException? resetError;
  AppException? resetPasswordError;
  Duration delay;

  int signInCalls = 0;
  int signOutCalls = 0;
  int resetCalls = 0;
  int resetPasswordCalls = 0;
  String? lastToken;
  String? lastEmail;
  String? lastPassword;
  bool? lastRemember;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    lastRemember = remember;

    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (signInError != null) throw signInError!;

    session = signInResult ?? testUser();
    return session!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    session = null;
  }

  @override
  Future<AuthUser?> currentUser() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (currentUserError != null) throw currentUserError!;
    return session;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    resetCalls++;
    lastEmail = email;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (resetError != null) throw resetError!;
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    resetPasswordCalls++;
    lastToken = token;
    lastEmail = email;
    lastPassword = password;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (resetPasswordError != null) throw resetPasswordError!;
  }
}

AuthUser testUser({
  int id = 1,
  String firstName = 'सीता',
  String? lastName = 'देवी',
  String email = 'committee@thakurbari.in',
  AccountStatus status = AccountStatus.active,
  String roleSlug = UserRole.admin,
  String roleName = 'Admin',
  Set<String> permissions = const {},
}) {
  return AuthUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: lastName == null ? firstName : '$firstName $lastName',
    email: email,
    status: status,
    role: UserRole(id: 2, slug: roleSlug, name: roleName),
    permissions: PermissionSet(permissions),
  );
}

extension TestUserPermissions on AuthUser {
  /// The same account holding exactly [permissions], for permission-driven
  /// widget tests.
  AuthUser copyWithPermissions(Set<String> permissions) => AuthUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    email: email,
    mobile: mobile,
    status: status,
    lastLoginAt: lastLoginAt,
    role: role,
    permissions: PermissionSet(permissions),
  );
}
