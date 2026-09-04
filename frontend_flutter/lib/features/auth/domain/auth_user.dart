import '../../../core/api/api_envelope.dart';
import '../../../core/auth/permissions.dart';

/// A role as returned by the API.
///
/// Only the identity of the role is modelled in Phase 0; permission keys arrive
/// with the Phase 2 permission matrix.
class UserRole {
  const UserRole({required this.id, required this.slug, required this.name});

  factory UserRole.fromJson(Map<String, dynamic> json) => UserRole(
    id: _asInt(json['id']) ?? 0,
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );

  static const String superAdmin = 'super-admin';
  static const String admin = 'admin';
  static const String treasurer = 'treasurer';
  static const String contentManager = 'content-manager';
  static const String viewer = 'viewer';

  final int id;
  final String slug;
  final String name;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// Account status, mirroring the `status` column on the backend.
enum AccountStatus {
  active('active'),
  inactive('inactive'),
  blocked('blocked');

  const AccountStatus(this.wireValue);

  final String wireValue;

  static AccountStatus fromWire(String? value) =>
      AccountStatus.values.firstWhere(
        (s) => s.wireValue == value,
        orElse: () => AccountStatus.inactive,
      );
}

/// The signed-in committee/admin user.
///
/// Parsing is defensive: optional fields defined by the specification
/// (`last_name`, `mobile`, `last_login_at`, `role`) may legitimately be absent.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.email,
    required this.status,
    this.lastName,
    this.fullName,
    this.mobile,
    this.lastLoginAt,
    this.role,
    this.permissions = PermissionSet.empty,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roleJson = ApiEnvelopeParser.asMap(json['role']);

    return AuthUser(
      id: UserRole._asInt(json['id']) ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String?,
      status: AccountStatus.fromWire(json['status'] as String?),
      lastLoginAt: DateTime.tryParse(json['last_login_at'] as String? ?? ''),
      role: roleJson == null ? null : UserRole.fromJson(roleJson),
      permissions: PermissionSet.fromJson(json['permissions']),
    );
  }

  final int id;
  final String firstName;
  final String? lastName;
  final String? fullName;
  final String email;
  final String? mobile;
  final AccountStatus status;
  final DateTime? lastLoginAt;
  final UserRole? role;

  /// What this account may do, as the server computed it.
  ///
  /// Used to decide what the admin UI offers. It is never the access control —
  /// every protected request is authorized again on the server.
  final PermissionSet permissions;

  /// Prefers the name the server composed, falling back to the parts.
  String get displayName {
    final composed = fullName?.trim();
    if (composed != null && composed.isNotEmpty) return composed;

    final parts = [firstName, lastName ?? ''].where((p) => p.trim().isNotEmpty);
    final joined = parts.join(' ').trim();
    return joined.isEmpty ? email : joined;
  }

  bool get isActive => status == AccountStatus.active;

  bool hasRole(String slug) => role?.slug == slug;

  bool can(String permission) => isActive && permissions.can(permission);
}
