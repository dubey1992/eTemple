import '../../../core/api/api_envelope.dart';
import '../../auth/domain/auth_user.dart';

/// A committee account as the user-management screens see it.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstName,
    required this.email,
    required this.status,
    this.lastName,
    this.fullName,
    this.mobile,
    this.role,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final roleJson = ApiEnvelopeParser.asMap(json['role']);

    return AdminUser(
      id: _asInt(json['id']) ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String?,
      status: AccountStatus.fromWire(json['status'] as String?),
      role: roleJson == null ? null : UserRole.fromJson(roleJson),
      lastLoginAt: DateTime.tryParse(json['last_login_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  final int id;
  final String firstName;
  final String? lastName;
  final String? fullName;
  final String email;
  final String? mobile;
  final AccountStatus status;
  final UserRole? role;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  String get displayName {
    final composed = fullName?.trim();
    if (composed != null && composed.isNotEmpty) return composed;

    final joined = [firstName, lastName ?? ''].join(' ').trim();
    return joined.isEmpty ? email : joined;
  }

  bool get isActive => status == AccountStatus.active;

  /// True for an account that has never signed in — usually one that has not
  /// yet followed its invitation link.
  bool get hasNeverSignedIn => lastLoginAt == null;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// A role together with the permissions it grants.
class ManagedRole {
  const ManagedRole({
    required this.id,
    required this.slug,
    required this.name,
    required this.permissions,
    required this.isEditable,
    this.description,
    this.userCount,
  });

  factory ManagedRole.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];

    return ManagedRole(
      id: AdminUser._asInt(json['id']) ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      permissions: permissions is List
          ? Set.unmodifiable(permissions.whereType<String>())
          : const <String>{},
      // Super Admin's set is fixed on the server; the matrix renders it
      // read-only rather than offering a save that would be refused.
      isEditable: json['is_editable'] as bool? ?? true,
      userCount: AdminUser._asInt(json['user_count']),
    );
  }

  final int id;
  final String slug;
  final String name;
  final String? description;
  final Set<String> permissions;
  final bool isEditable;
  final int? userCount;

  bool grants(String permission) => permissions.contains(permission);
}

/// One permission key with its human label.
class PermissionOption {
  const PermissionOption({required this.key, required this.label});

  factory PermissionOption.fromJson(Map<String, dynamic> json) =>
      PermissionOption(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  final String key;
  final String label;
}

/// A module's worth of permissions, as the matrix renders them.
class PermissionModule {
  const PermissionModule({
    required this.module,
    required this.label,
    required this.phase,
    required this.permissions,
  });

  factory PermissionModule.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];

    return PermissionModule(
      module: json['module'] as String? ?? '',
      label: json['label'] as String? ?? '',
      phase: AdminUser._asInt(json['phase']) ?? 0,
      permissions: permissions is List
          ? permissions
                .map(ApiEnvelopeParser.asMap)
                .whereType<Map<String, dynamic>>()
                .map(PermissionOption.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String module;
  final String label;

  /// The phase that builds this module. Anything beyond the phases delivered so
  /// far can be granted but is not yet enforced anywhere, and the UI says so
  /// rather than implying the toggle already does something.
  final int phase;
  final List<PermissionOption> permissions;
}

/// The catalogue the permission matrix renders.
class PermissionCatalogue {
  const PermissionCatalogue(this.modules);

  factory PermissionCatalogue.fromJson(Map<String, dynamic> json) {
    final modules = json['modules'];

    return PermissionCatalogue(
      modules is List
          ? modules
                .map(ApiEnvelopeParser.asMap)
                .whereType<Map<String, dynamic>>()
                .map(PermissionModule.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  static const PermissionCatalogue empty = PermissionCatalogue(
    <PermissionModule>[],
  );

  final List<PermissionModule> modules;

  bool get isEmpty => modules.isEmpty;
}

/// One recorded sign-in attempt.
class LoginAttempt {
  const LoginAttempt({
    required this.id,
    required this.email,
    required this.outcome,
    required this.successful,
    this.ipAddress,
    this.userAgent,
    this.at,
  });

  factory LoginAttempt.fromJson(Map<String, dynamic> json) => LoginAttempt(
    id: AdminUser._asInt(json['id']) ?? 0,
    email: json['email'] as String? ?? '',
    outcome: json['outcome'] as String? ?? '',
    successful: json['successful'] as bool? ?? false,
    ipAddress: json['ip_address'] as String?,
    userAgent: json['user_agent'] as String?,
    at: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  final int id;
  final String email;
  final String outcome;
  final bool successful;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? at;
}

/// The fields an administrator can set on an account.
///
/// A separate type from [AdminUser] so the write contract is explicit: the
/// password is never among them — a new member sets their own through the
/// mailed reset link.
class AdminUserDraft {
  const AdminUserDraft({
    required this.firstName,
    required this.email,
    required this.roleId,
    required this.status,
    this.lastName,
    this.mobile,
  });

  final String firstName;
  final String? lastName;
  final String email;
  final String? mobile;
  final int roleId;
  final AccountStatus status;

  Map<String, Object?> toJson() => {
    'first_name': firstName.trim(),
    'last_name': _nullIfBlank(lastName),
    'email': email.trim().toLowerCase(),
    'mobile': _nullIfBlank(mobile),
    'role_id': roleId,
    'status': status.wireValue,
  };

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
