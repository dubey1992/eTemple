/// Permission keys, mirroring `App\Support\Permission` on the backend.
///
/// The client uses these only to decide what to *show*. Every one of them is
/// checked again by the server on the request itself — the specification is
/// explicit that hiding a button is never the authorization control.
class Permissions {
  const Permissions._();

  static const String contentView = 'content.view';
  static const String contentManage = 'content.manage';

  static const String usersView = 'users.view';
  static const String usersManage = 'users.manage';

  static const String rolesView = 'roles.view';
  static const String rolesManage = 'roles.manage';

  static const String securityView = 'security.view';
  static const String securityManage = 'security.manage';

  static const String templeManage = 'temple.manage';
  static const String eventsManage = 'events.manage';
  static const String mediaManage = 'media.manage';
  static const String donationsView = 'donations.view';
  static const String donationsManage = 'donations.manage';
  static const String enquiriesManage = 'enquiries.manage';
  static const String announcementsManage = 'announcements.manage';
  static const String accountsView = 'accounts.view';
  static const String accountsManage = 'accounts.manage';
  static const String reportsView = 'reports.view';
  static const String reportsExport = 'reports.export';

  /// Reading the audit trail. Its own key rather than `security.view`, which is
  /// the login history: the trail carries donor names and enquiry references,
  /// so it is a stricter thing to hand out. Super Admin holds it by default and
  /// nobody else does, including Admin.
  static const String auditView = 'audit.view';
}

/// The signed-in user's effective permissions.
///
/// A tiny value type rather than a bare `List<String>` so call sites read as
/// `permissions.can(Permissions.usersManage)` and an empty set is explicit.
class PermissionSet {
  const PermissionSet(this._keys);

  factory PermissionSet.fromJson(Object? json) {
    if (json is! List) return PermissionSet.empty;
    return PermissionSet(json.whereType<String>().toSet());
  }

  static const PermissionSet empty = PermissionSet(<String>{});

  final Set<String> _keys;

  bool can(String permission) => _keys.contains(permission);

  /// True when the user holds at least one of [permissions].
  bool canAny(Iterable<String> permissions) => permissions.any(can);

  bool get isEmpty => _keys.isEmpty;

  int get length => _keys.length;

  List<String> toList() => List.unmodifiable(_keys.toList()..sort());
}
