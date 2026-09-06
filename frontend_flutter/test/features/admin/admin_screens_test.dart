import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/admin/data/admin_providers.dart';
import 'package:rkt_web/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_role_permissions_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_roles_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_user_editor_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_users_screen.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/domain/auth_user.dart';

import '../../support/fake_admin_repository.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/pump_app.dart';

/// Signs in as an account holding exactly [permissions].
Future<void> pumpAdmin(
  WidgetTester tester,
  Widget screen, {
  required Set<String> permissions,
  FakeAdminRepository? admin,
  Size? surfaceSize,
}) async {
  final user = testUser().copyWithPermissions(permissions);

  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize ?? const Size(1024, 1600),
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: user),
      ),
      adminRepositoryProvider.overrideWithValue(admin ?? FakeAdminRepository()),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminDashboardScreen', () {
    testWidgets('offers only what the account is permitted to do', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        permissions: {Permissions.contentManage},
      );

      expect(find.byKey(const Key('dash-pages')), findsOneWidget);
      expect(find.byKey(const Key('dash-site-settings')), findsOneWidget);
      // No users or roles permission, so those doors are not offered.
      expect(find.byKey(const Key('dash-users')), findsNothing);
      expect(find.byKey(const Key('dash-roles')), findsNothing);
    });

    testWidgets('a full administrator sees every entry', (tester) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        permissions: {
          Permissions.contentManage,
          Permissions.usersView,
          Permissions.rolesView,
        },
      );

      expect(find.byKey(const Key('dash-pages')), findsOneWidget);
      expect(find.byKey(const Key('dash-users')), findsOneWidget);
      expect(find.byKey(const Key('dash-roles')), findsOneWidget);
    });

    testWidgets('an account with no admin rights is told so plainly', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        permissions: const {},
      );

      expect(find.byKey(const Key('dash-no-access')), findsOneWidget);
      expect(find.byKey(const Key('dash-users')), findsNothing);
    });
  });

  group('AdminUsersScreen', () {
    testWidgets('lists accounts with role and status', (tester) async {
      final admin = FakeAdminRepository(
        userList: [
          testAdminUser(id: 1),
          testAdminUser(
            id: 2,
            firstName: 'राम',
            lastName: null,
            email: 'ram@thakurbari.test',
            status: AccountStatus.blocked,
          ),
        ],
      );

      await pumpAdmin(
        tester,
        const AdminUsersScreen(),
        permissions: {Permissions.usersView, Permissions.usersManage},
        admin: admin,
      );

      expect(find.byKey(const Key('user-tile-1')), findsOneWidget);
      expect(find.byKey(const Key('user-tile-2')), findsOneWidget);
      expect(find.text('अवरुद्ध'), findsOneWidget);
    });

    testWidgets('hides the create button without manage permission', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminUsersScreen(),
        permissions: {Permissions.usersView},
        admin: FakeAdminRepository(userList: [testAdminUser()]),
      );

      expect(find.byKey(const Key('users-new')), findsNothing);
    });

    testWidgets('flags an account that has never signed in', (tester) async {
      await pumpAdmin(
        tester,
        const AdminUsersScreen(),
        permissions: {Permissions.usersView},
        admin: FakeAdminRepository(userList: [testAdminUser()]),
      );

      expect(find.text('कभी साइन इन नहीं किया'), findsOneWidget);
    });

    testWidgets('a refused request shows the unauthorized state', (
      tester,
    ) async {
      // The server is what refuses; the UI reflects that rather than pretending
      // the list is empty.
      await pumpAdmin(
        tester,
        const AdminUsersScreen(),
        permissions: {Permissions.usersView},
        admin: FakeAdminRepository(
          usersError: const AppException(code: ErrorCode.forbidden),
        ),
      );

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
    });

    testWidgets('an outage offers a retry', (tester) async {
      await pumpAdmin(
        tester,
        const AdminUsersScreen(),
        permissions: {Permissions.usersView},
        admin: FakeAdminRepository(
          usersError: const AppException(code: ErrorCode.network),
        ),
      );

      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });
  });

  group('AdminUserEditorScreen', () {
    FakeAdminRepository repo() => FakeAdminRepository(
      userList: [testAdminUser(id: 1)],
      roleList: [
        testRole(id: 4, name: 'Content Manager'),
        testRole(),
      ],
    );

    testWidgets('creating an account offers no password field', (tester) async {
      final admin = repo();
      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(),
        permissions: {Permissions.usersManage},
        admin: admin,
      );

      // The password is set by the member through a mailed link; offering a
      // field here would mean the committee passing one around.
      expect(find.text('पासवर्ड'), findsNothing);
      expect(find.byKey(const Key('user-first-name')), findsOneWidget);
      expect(
        find.text(
          'नया सदस्य ईमेल पर भेजे गए लिंक से अपना पासवर्ड स्वयं बनाएगा।',
        ),
        findsOneWidget,
      );
    });

    testWidgets('validates required fields before calling the API', (
      tester,
    ) async {
      final admin = repo();
      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(),
        permissions: {Permissions.usersManage},
        admin: admin,
      );

      await tester.tap(find.byKey(const Key('user-save')));
      await tester.pumpAndSettle();

      expect(find.text('यह जानकारी आवश्यक है'), findsWidgets);
      expect(admin.createCalls, 0);
    });

    testWidgets('rejects a malformed e-mail client-side', (tester) async {
      final admin = repo();
      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(),
        permissions: {Permissions.usersManage},
        admin: admin,
      );

      await tester.enterText(find.byKey(const Key('user-first-name')), 'सीता');
      await tester.enterText(
        find.byKey(const Key('user-email')),
        'not-an-email',
      );
      await tester.tap(find.byKey(const Key('user-save')));
      await tester.pumpAndSettle();

      expect(find.text('कृपया वैध ईमेल पता दर्ज करें'), findsOneWidget);
      expect(admin.createCalls, 0);
    });

    testWidgets('creates an account with a normalised e-mail', (tester) async {
      final admin = repo();
      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(),
        permissions: {Permissions.usersManage},
        admin: admin,
      );

      await tester.enterText(find.byKey(const Key('user-first-name')), 'सीता');
      await tester.enterText(
        find.byKey(const Key('user-email')),
        '  Sita@Thakurwadi.TEST ',
      );
      await tester.tap(find.byKey(const Key('user-save')));
      await tester.pumpAndSettle();

      expect(admin.createCalls, 1);
      expect(admin.lastDraft!.toJson()['email'], 'sita@thakurwadi.test');
      expect(admin.lastDraft!.toJson()['last_name'], isNull);
    });

    testWidgets('shows the server guard refusal against the right field', (
      tester,
    ) async {
      final admin = repo()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'status': ['You cannot deactivate or block your own account.'],
          },
        );

      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(userId: 1),
        permissions: {Permissions.usersManage},
        admin: admin,
      );

      await tester.tap(find.byKey(const Key('user-save')));
      await tester.pumpAndSettle();

      // The specific reason, not a generic "something is invalid". It appears
      // twice on purpose: in the banner at the top, which stays visible while
      // scrolling, and inline on the field it belongs to.
      expect(
        find.text('You cannot deactivate or block your own account.'),
        findsNWidgets(2),
      );
    });

    testWidgets('a read-only viewer cannot edit or save', (tester) async {
      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(userId: 1),
        permissions: {Permissions.usersView},
        admin: repo(),
      );

      expect(find.byKey(const Key('user-save')), findsNothing);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('user-first-name')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.enabled, isFalse);
    });

    testWidgets('login history is hidden without the security permission', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(userId: 1),
        permissions: {Permissions.usersManage},
        admin: repo(),
      );

      expect(find.text('लॉगिन इतिहास'), findsNothing);
    });

    testWidgets('login history appears with the security permission', (
      tester,
    ) async {
      final admin = repo()
        ..history = [testAttempt(id: 1), testAttempt(id: 2, successful: false)];

      await pumpAdmin(
        tester,
        const AdminUserEditorScreen(userId: 1),
        permissions: {Permissions.usersManage, Permissions.securityView},
        admin: admin,
      );

      expect(find.text('लॉगिन इतिहास'), findsOneWidget);
      expect(find.byKey(const Key('login-attempt-1')), findsOneWidget);
      // Failures are shown, not filtered out.
      expect(find.text('असफल'), findsOneWidget);
    });
  });

  group('roles and the permission matrix', () {
    FakeAdminRepository repo() => FakeAdminRepository(
      roleList: [
        testRole(
          id: 1,
          slug: 'super-admin',
          name: 'Super Admin',
          permissions: {Permissions.contentView, Permissions.contentManage},
          isEditable: false,
        ),
        testRole(id: 5),
      ],
    );

    testWidgets('lists roles with their permission counts', (tester) async {
      await pumpAdmin(
        tester,
        const AdminRolesScreen(),
        permissions: {Permissions.rolesView},
        admin: repo(),
      );

      expect(find.byKey(const Key('role-tile-super-admin')), findsOneWidget);
      expect(find.byKey(const Key('role-tile-viewer')), findsOneWidget);
    });

    testWidgets('the matrix groups permissions by module', (tester) async {
      await pumpAdmin(
        tester,
        const AdminRolePermissionsScreen(roleId: 5),
        permissions: {Permissions.rolesView, Permissions.rolesManage},
        admin: repo(),
      );

      expect(find.byKey(const Key('module-content')), findsOneWidget);
      expect(find.byKey(const Key('module-donations')), findsOneWidget);
      expect(find.byKey(const Key('perm-content.manage')), findsOneWidget);
    });

    testWidgets('a module from a future phase is labelled as not yet active', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminRolePermissionsScreen(roleId: 5),
        permissions: {Permissions.rolesView, Permissions.rolesManage},
        admin: repo(),
      );

      // Donations is phase 6; the committee should not think the toggle already
      // does something.
      expect(find.text('चरण 6 में उपलब्ध होगा'), findsOneWidget);
    });

    testWidgets('toggling and saving sends the new set', (tester) async {
      final admin = repo();
      await pumpAdmin(
        tester,
        const AdminRolePermissionsScreen(roleId: 5),
        permissions: {Permissions.rolesView, Permissions.rolesManage},
        admin: admin,
      );

      await tester.tap(find.byKey(const Key('perm-content.manage')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('matrix-save')));
      await tester.pumpAndSettle();

      expect(admin.permissionSaveCalls, 1);
      expect(admin.lastPermissions, contains(Permissions.contentManage));
      expect(admin.lastPermissions, contains(Permissions.contentView));
    });

    testWidgets('Super Admin renders read-only with an explanation', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminRolePermissionsScreen(roleId: 1),
        permissions: {Permissions.rolesView, Permissions.rolesManage},
        admin: repo(),
      );

      expect(find.byKey(const Key('role-fixed-notice')), findsOneWidget);
      expect(find.byKey(const Key('matrix-save')), findsNothing);

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('perm-content.manage')),
      );
      expect(checkbox.onChanged, isNull);
    });

    testWidgets('a reader without roles.manage cannot save', (tester) async {
      await pumpAdmin(
        tester,
        const AdminRolePermissionsScreen(roleId: 5),
        permissions: {Permissions.rolesView},
        admin: repo(),
      );

      expect(find.byKey(const Key('matrix-save')), findsNothing);
    });

    testWidgets('a server refusal is shown with its reason', (tester) async {
      final admin = repo()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'permissions': ['Unknown permission keys: made.up'],
          },
        );

      await pumpAdmin(
        tester,
        const AdminRolePermissionsScreen(roleId: 5),
        permissions: {Permissions.rolesView, Permissions.rolesManage},
        admin: admin,
      );

      await tester.tap(find.byKey(const Key('matrix-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('matrix-error')), findsOneWidget);
      expect(find.text('Unknown permission keys: made.up'), findsOneWidget);
    });
  });
}
