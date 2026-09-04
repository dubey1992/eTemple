import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/auth/permissions.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/admin_models.dart';
import 'admin_repository.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.watch(apiClientProvider)),
);

/// What the signed-in account may do, as the server reported it on /auth/me.
///
/// Drives which admin entries and actions are offered. It is a courtesy for the
/// operator, never the access control — the server authorizes every request
/// independently, which the backend tests assert by calling the API directly.
final permissionsProvider = Provider<PermissionSet>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null || !user.isActive) return PermissionSet.empty;

  return user.permissions;
});

/// Convenience for a single check inside a widget.
final canProvider = Provider.family<bool, String>(
  (ref, permission) => ref.watch(permissionsProvider).can(permission),
);

final adminUsersProvider = FutureProvider<List<AdminUser>>(
  (ref) => ref.watch(adminRepositoryProvider).users(),
);

final adminUserProvider = FutureProvider.family<AdminUser, int>(
  (ref, id) => ref.watch(adminRepositoryProvider).user(id),
);

final adminRolesProvider = FutureProvider<List<ManagedRole>>(
  (ref) => ref.watch(adminRepositoryProvider).roles(),
);

final permissionCatalogueProvider = FutureProvider<PermissionCatalogue>(
  (ref) => ref.watch(adminRepositoryProvider).permissionCatalogue(),
);

final loginHistoryProvider = FutureProvider.family<List<LoginAttempt>, int>(
  (ref, id) => ref.watch(adminRepositoryProvider).loginHistory(id),
);
