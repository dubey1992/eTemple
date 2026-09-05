import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/features/accounts/presentation/admin_accounting_categories_screen.dart';
import 'package:rkt_web/features/accounts/presentation/admin_accounting_settings_screen.dart';
import 'package:rkt_web/features/accounts/presentation/admin_accounts_screen.dart';
import 'package:rkt_web/features/accounts/presentation/admin_transaction_editor_screen.dart';
import 'package:rkt_web/features/accounts/presentation/transparency_screen.dart';
import 'package:rkt_web/features/admin/data/admin_providers.dart';
import 'package:rkt_web/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_role_permissions_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_roles_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_user_editor_screen.dart';
import 'package:rkt_web/features/admin/presentation/admin_users_screen.dart';
import 'package:rkt_web/features/announcements/presentation/admin_announcement_editor_screen.dart';
import 'package:rkt_web/features/announcements/presentation/admin_announcements_screen.dart';
import 'package:rkt_web/features/audit/presentation/admin_audit_screen.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/auth/presentation/forgot_password_screen.dart';
import 'package:rkt_web/features/auth/presentation/login_screen.dart';
import 'package:rkt_web/features/auth/presentation/reset_password_screen.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/presentation/admin_page_editor_screen.dart';
import 'package:rkt_web/features/content/presentation/admin_pages_screen.dart';
import 'package:rkt_web/features/content/presentation/admin_site_settings_screen.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/content/presentation/page_screen.dart';
import 'package:rkt_web/features/donations/presentation/admin_donation_editor_screen.dart';
import 'package:rkt_web/features/donations/presentation/admin_donation_settings_screen.dart';
import 'package:rkt_web/features/donations/presentation/admin_donations_screen.dart';
import 'package:rkt_web/features/donations/presentation/donate_screen.dart';
import 'package:rkt_web/features/enquiries/presentation/admin_enquiries_screen.dart';
import 'package:rkt_web/features/enquiries/presentation/admin_enquiry_detail_screen.dart';
import 'package:rkt_web/features/enquiries/presentation/contact_screen.dart';
import 'package:rkt_web/features/events/presentation/admin_event_editor_screen.dart';
import 'package:rkt_web/features/events/presentation/admin_events_screen.dart';
import 'package:rkt_web/features/events/presentation/event_detail_screen.dart';
import 'package:rkt_web/features/events/presentation/events_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_album_editor_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_albums_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_media_editor_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_media_screen.dart';
import 'package:rkt_web/features/media/presentation/gallery_screen.dart';
import 'package:rkt_web/features/reports/presentation/admin_report_screen.dart';
import 'package:rkt_web/features/reports/presentation/admin_reports_screen.dart';
import 'package:rkt_web/features/shell/presentation/not_found_screen.dart';
import 'package:rkt_web/features/temple/presentation/admin_committee_member_screen.dart';
import 'package:rkt_web/features/temple/presentation/admin_committee_screen.dart';
import 'package:rkt_web/features/temple/presentation/admin_temple_profile_screen.dart';
import 'package:rkt_web/features/temple/presentation/committee_screen.dart';

import '../support/fake_admin_repository.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_content_repository.dart';
import '../support/pump_app.dart';

/// Every screen, at every width, in both languages.
///
/// The per-feature suites each test one screen carefully. This tests **all of
/// them shallowly**, which catches a different class of defect entirely: a
/// layout that overflows only at 360px, a screen that throws before it paints,
/// and — the one that matters most on this project — a Hindi string long enough
/// to break a row that the English string fits into.
///
/// Devanagari is materially wider than Latin for the same meaning, so a design
/// checked in English is not a design checked. Everything here runs in Hindi
/// first, because Hindi is the product's default language, and then again in
/// English.
const _phone = Size(360, 780);
const _tablet = Size(768, 1024);
const _desktop = Size(1440, 900);

/// A screen and the arguments it needs, with a name for the failure message.
typedef _Case = ({String name, Widget Function() build, bool admin});

_Case _public(String name, Widget Function() build) =>
    (name: name, build: build, admin: false);

_Case _admin(String name, Widget Function() build) =>
    (name: name, build: build, admin: true);

/// Every permission there is.
///
/// The sweep is about layout, not authorization — the per-feature suites and
/// the backend's own route sweep prove who may see what. An account holding
/// everything is what renders the *most* on each screen, which is the hardest
/// case for a 360px column.
final _allPermissions = <String>{
  Permissions.contentView,
  Permissions.contentManage,
  Permissions.usersView,
  Permissions.usersManage,
  Permissions.rolesView,
  Permissions.rolesManage,
  Permissions.securityView,
  Permissions.securityManage,
  Permissions.templeManage,
  Permissions.eventsManage,
  Permissions.mediaManage,
  Permissions.donationsView,
  Permissions.donationsManage,
  Permissions.enquiriesManage,
  Permissions.announcementsManage,
  Permissions.accountsView,
  Permissions.accountsManage,
  Permissions.reportsView,
  Permissions.reportsExport,
  Permissions.auditView,
};

List<_Case> _screens() => [
  // --- what a villager sees ----------------------------------------------
  _public('HomeScreen', HomeScreen.new),
  _public('PageScreen', () => const PageScreen(slug: 'about')),
  _public('EventsScreen', EventsScreen.new),
  _public('EventDetailScreen', () => const EventDetailScreen(eventId: 1)),
  _public('GalleryScreen', GalleryScreen.new),
  _public('CommitteeScreen', CommitteeScreen.new),
  _public('DonateScreen', DonateScreen.new),
  _public('ContactScreen', ContactScreen.new),
  _public('TransparencyScreen', TransparencyScreen.new),
  _public('NotFoundScreen', NotFoundScreen.new),

  // --- getting in ---------------------------------------------------------
  _public('LoginScreen', LoginScreen.new),
  _public('ForgotPasswordScreen', ForgotPasswordScreen.new),
  _public(
    'ResetPasswordScreen',
    () => const ResetPasswordScreen(token: 't', email: 'a@b.test'),
  ),

  // --- the console --------------------------------------------------------
  _admin('AdminDashboardScreen', AdminDashboardScreen.new),
  _admin('AdminPagesScreen', AdminPagesScreen.new),
  _admin('AdminPageEditorScreen', () => const AdminPageEditorScreen(pageId: 1)),
  _admin('AdminSiteSettingsScreen', AdminSiteSettingsScreen.new),
  _admin('AdminUsersScreen', AdminUsersScreen.new),
  _admin('AdminUserEditorScreen', AdminUserEditorScreen.new),
  _admin('AdminRolesScreen', AdminRolesScreen.new),
  _admin(
    'AdminRolePermissionsScreen',
    () => const AdminRolePermissionsScreen(roleId: 1),
  ),
  _admin('AdminTempleProfileScreen', AdminTempleProfileScreen.new),
  _admin('AdminCommitteeScreen', AdminCommitteeScreen.new),
  _admin('AdminCommitteeMemberScreen', AdminCommitteeMemberScreen.new),
  _admin('AdminEventsScreen', AdminEventsScreen.new),
  _admin('AdminEventEditorScreen', AdminEventEditorScreen.new),
  _admin('AdminMediaScreen', AdminMediaScreen.new),
  _admin('AdminMediaEditorScreen', AdminMediaEditorScreen.new),
  _admin('AdminAlbumsScreen', AdminAlbumsScreen.new),
  _admin('AdminAlbumEditorScreen', AdminAlbumEditorScreen.new),
  _admin('AdminDonationsScreen', AdminDonationsScreen.new),
  _admin('AdminDonationEditorScreen', AdminDonationEditorScreen.new),
  _admin('AdminDonationSettingsScreen', AdminDonationSettingsScreen.new),
  _admin('AdminEnquiriesScreen', AdminEnquiriesScreen.new),
  _admin(
    'AdminEnquiryDetailScreen',
    () => const AdminEnquiryDetailScreen(id: 1),
  ),
  _admin('AdminAnnouncementsScreen', AdminAnnouncementsScreen.new),
  _admin('AdminAnnouncementEditorScreen', AdminAnnouncementEditorScreen.new),
  _admin('AdminAccountsScreen', AdminAccountsScreen.new),
  _admin('AdminTransactionEditorScreen', AdminTransactionEditorScreen.new),
  _admin(
    'AdminAccountingCategoriesScreen',
    AdminAccountingCategoriesScreen.new,
  ),
  _admin('AdminAccountingSettingsScreen', AdminAccountingSettingsScreen.new),
  _admin('AdminReportsScreen', AdminReportsScreen.new),
  _admin(
    'AdminReportScreen',
    () => const AdminReportScreen(reportKey: 'donations'),
  ),
  _admin('AdminAuditScreen', AdminAuditScreen.new),
];

Future<void> _pumpCase(
  WidgetTester tester,
  _Case screen,
  Size size,
  Locale locale,
) async {
  final user = testUser().copyWithPermissions(_allPermissions);

  await pumpScreen(
    tester,
    Scaffold(body: screen.build()),
    locale: locale,
    surfaceSize: size,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: screen.admin ? user : null),
      ),
      adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
      permissionsProvider.overrideWithValue(PermissionSet(_allPermissions)),
      contentRepositoryProvider.overrideWithValue(
        FakeContentRepository(
          pages: {'about': testPage()},
          settings: testSettings(),
        ),
      ),
    ],
  );

  // Not pumpAndSettle: a screen that is still loading may hold an indefinite
  // progress animation, and waiting for it to stop would hang rather than fail.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('every screen renders', () {
    for (final size in const [_phone, _tablet, _desktop]) {
      testWidgets('at ${size.width.toInt()}px, in Hindi', (tester) async {
        // Every screen is swept before anything is asserted, so one broken
        // layout does not hide the next twenty.
        final failures = <String>[];

        for (final screen in _screens()) {
          await _pumpCase(tester, screen, size, AppLocales.hindi);

          final error = tester.takeException();
          if (error != null) failures.add('${screen.name}: $error');
        }

        expect(
          failures,
          isEmpty,
          reason: 'at ${size.width.toInt()}px in Hindi',
        );
      });
    }

    /// English second, and only at the narrowest width — the one where a long
    /// string breaks a row. Hindi is checked at all three because it is the
    /// default and the wider script.
    testWidgets('at 360px, in English', (tester) async {
      final failures = <String>[];

      for (final screen in _screens()) {
        await _pumpCase(tester, screen, _phone, AppLocales.english);

        final error = tester.takeException();
        if (error != null) failures.add('${screen.name}: $error');
      }

      expect(failures, isEmpty, reason: 'at 360px in English');
    });
  });
}
