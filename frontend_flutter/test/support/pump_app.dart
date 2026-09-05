import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override is exported from the misc library in Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/app/routing/route_paths.dart';
import 'package:rkt_web/app/theme/app_theme.dart';
import 'package:rkt_web/features/accounts/data/accounts_providers.dart';
import 'package:rkt_web/features/announcements/data/announcement_providers.dart';
import 'package:rkt_web/features/audit/data/audit_providers.dart';
import 'package:rkt_web/features/reports/data/reports_providers.dart';
import 'package:rkt_web/features/donations/data/donation_providers.dart';
import 'package:rkt_web/features/enquiries/data/enquiry_providers.dart';
import 'package:rkt_web/features/events/data/event_providers.dart';
import 'package:rkt_web/features/media/data/media_providers.dart';
import 'package:rkt_web/features/temple/data/temple_providers.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import 'fake_accounts_repository.dart';
import 'fake_announcement_repository.dart';
import 'fake_audit_repository.dart';
import 'fake_reports_repository.dart';
import 'fake_donation_repository.dart';
import 'fake_enquiry_repository.dart';
import 'fake_event_repository.dart';
import 'fake_media_repository.dart';
import 'fake_temple_repository.dart';
import 'no_network.dart';

/// Key on the stand-in screen the admin route renders in these tests.
const adminPlaceholderKey = Key('test-admin-placeholder');

/// Key on the stand-in screen the forgot-password route renders.
const forgotPasswordPlaceholderKey = Key('test-forgot-password-placeholder');

/// Key on the stand-in screen the committee-list route renders.
const committeeListPlaceholderKey = Key('test-committee-placeholder');

/// Key on the stand-in screen the public gallery route renders.
const galleryPlaceholderKey = Key('test-gallery-placeholder');

/// Key on the stand-in screen the media-library route renders.
const mediaListPlaceholderKey = Key('test-media-placeholder');

/// Key on the stand-in screen the albums route renders.
const albumListPlaceholderKey = Key('test-albums-placeholder');

/// Key on the stand-in screen the public donate route renders.
const donatePlaceholderKey = Key('test-donate-placeholder');

/// Key on the stand-in screen the donation register renders.
const donationsPlaceholderKey = Key('test-donations-placeholder');

/// Key on the stand-in screen the public contact route renders.
const contactPlaceholderKey = Key('test-contact-placeholder');

/// Key on the stand-in screen the enquiry inbox renders.
const enquiriesPlaceholderKey = Key('test-enquiries-placeholder');

/// Key on the stand-in screen the announcements list renders.
const announcementsPlaceholderKey = Key('test-announcements-placeholder');

/// Key on the stand-in screen the public transparency route renders.
const transparencyPlaceholderKey = Key('test-transparency-placeholder');

/// Key on the stand-in screen the ledger renders.
const accountsPlaceholderKey = Key('test-accounts-placeholder');

/// Key on the stand-in screen the accounting categories render.
const accountingCategoriesPlaceholderKey = Key('test-categories-placeholder');

/// Key on the stand-in screen the report catalogue renders.
const reportsPlaceholderKey = Key('test-reports-placeholder');

/// Pumps a single screen inside the real theme and localization setup.
///
/// A minimal router is provided so screens that navigate (the login screen, for
/// example) behave as they do in the application instead of throwing.
///
/// The temple profile (Phase 3), the calendar (Phase 4), the gallery (Phase 5)
/// and the donation details (Phase 6) are read by shared chrome — the header,
/// the hero, the home page, even the sign-in page — so stubs for all four are
/// always supplied. Pass [temple], [events], [media] or [donations] to script
/// them, including making them fail. So are the enquiry, announcement and
/// accounts repositories, for the same reason: any screen may reach one.
///
/// An [ApiClient] that refuses every request is installed as well, so a
/// repository nobody remembered to fake fails loudly instead of quietly
/// succeeding against whatever development server happens to be running.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = AppLocales.hindi,
  Size? surfaceSize,
  FakeTempleRepository? temple,
  FakeEventRepository? events,
  FakeMediaRepository? media,
  FakeDonationRepository? donations,
  FakeEnquiryRepository? enquiries,
  FakeAnnouncementRepository? announcements,
  FakeAccountsRepository? accounts,
  FakeReportsRepository? reports,
  FakeAuditRepository? audit,
}) async {
  if (surfaceSize != null) {
    // Set the logical size directly: devicePixelRatio 1.0 makes the physical
    // size and the logical size the same, so the breakpoints under test are the
    // ones a browser at this width would apply.
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(path: RoutePaths.home, builder: (_, _) => child),
      GoRoute(
        path: RoutePaths.admin,
        builder: (_, _) =>
            const Scaffold(key: adminPlaceholderKey, body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (_, _) => const Scaffold(
          key: forgotPasswordPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminCommittee,
        builder: (_, _) => const Scaffold(
          key: committeeListPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminTempleProfile,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.committee,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.gallery,
        builder: (_, _) =>
            const Scaffold(key: galleryPlaceholderKey, body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.adminMedia,
        builder: (_, _) => const Scaffold(
          key: mediaListPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminAlbums,
        builder: (_, _) => const Scaffold(
          key: albumListPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.donate,
        builder: (_, _) =>
            const Scaffold(key: donatePlaceholderKey, body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.adminDonations,
        builder: (_, _) => const Scaffold(
          key: donationsPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminDonationSettings,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.contact,
        builder: (_, _) =>
            const Scaffold(key: contactPlaceholderKey, body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.adminAnnouncements,
        builder: (_, _) => const Scaffold(
          key: announcementsPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminEnquiries,
        builder: (_, _) => const Scaffold(
          key: enquiriesPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.transparency,
        builder: (_, _) => const Scaffold(
          key: transparencyPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminAccounts,
        builder: (_, _) => const Scaffold(
          key: accountsPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminAccountingCategories,
        builder: (_, _) => const Scaffold(
          key: accountingCategoriesPlaceholderKey,
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminAccountingSettings,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.adminReports,
        builder: (_, _) =>
            const Scaffold(key: reportsPlaceholderKey, body: SizedBox.shrink()),
      ),
      GoRoute(
        path: RoutePaths.adminEvents,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        noNetworkOverride,
        templeRepositoryProvider.overrideWithValue(
          temple ?? FakeTempleRepository(profile: testProfile()),
        ),
        eventRepositoryProvider.overrideWithValue(
          events ?? FakeEventRepository(),
        ),
        enquiryRepositoryProvider.overrideWithValue(
          enquiries ?? FakeEnquiryRepository(),
        ),
        announcementRepositoryProvider.overrideWithValue(
          announcements ?? FakeAnnouncementRepository(),
        ),
        accountsRepositoryProvider.overrideWithValue(
          accounts ?? FakeAccountsRepository(),
        ),
        reportsRepositoryProvider.overrideWithValue(
          reports ?? FakeReportsRepository(),
        ),
        auditRepositoryProvider.overrideWithValue(
          audit ?? FakeAuditRepository(),
        ),
        mediaRepositoryProvider.overrideWithValue(
          media ?? FakeMediaRepository(),
        ),
        donationRepositoryProvider.overrideWithValue(
          donations ?? FakeDonationRepository(),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
}
