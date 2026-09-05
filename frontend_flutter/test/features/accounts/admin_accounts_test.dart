import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/accounts/domain/account.dart';
import 'package:rkt_web/features/accounts/presentation/admin_accounting_categories_screen.dart';
import 'package:rkt_web/features/accounts/presentation/admin_accounting_settings_screen.dart';
import 'package:rkt_web/features/accounts/presentation/admin_accounts_screen.dart';
import 'package:rkt_web/features/accounts/presentation/admin_transaction_editor_screen.dart';
import 'package:rkt_web/features/admin/data/admin_providers.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import '../../support/fake_accounts_repository.dart';
import '../../support/pump_app.dart';

/// The committee's side of the books.
void main() {
  late AppLocalizations hi;

  setUpAll(() async {
    hi = await AppLocalizations.delegate.load(AppLocales.hindi);
  });

  Future<void> pumpAdmin(
    WidgetTester tester,
    Widget screen,
    FakeAccountsRepository accounts, {
    Set<String> permissions = const {
      Permissions.accountsView,
      Permissions.accountsManage,
    },
  }) async {
    await pumpScreen(
      tester,
      // Wrapped in a Scaffold: these screens are rendered inside the admin
      // shell in the application, and a bare pump has no Material ancestor.
      Scaffold(body: screen),
      accounts: accounts,
      surfaceSize: const Size(1200, 1600),
      overrides: [
        permissionsProvider.overrideWithValue(PermissionSet(permissions)),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('the ledger', () {
    testWidgets('shows approved money and names what is still to be checked', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountsScreen(),
        FakeAccountsRepository(
          transactions: [testTransaction()],
          summary: const AccountsSummary(
            incomePaise: 870000,
            expensePaise: 300000,
            netPaise: 570000,
            approvedCount: 3,
            pendingCount: 2,
            pendingIncomePaise: 0,
            pendingExpensePaise: 999900,
            reversedCount: 1,
          ),
        ),
      );

      expect(find.byKey(const Key('accounts-income')), findsOneWidget);
      expect(find.text('₹8,700.00'), findsOneWidget);
      expect(find.text('₹3,000.00'), findsOneWidget);

      // Pending money is named as pending, and is in none of the figures above.
      expect(find.byKey(const Key('accounts-pending-note')), findsOneWidget);
      expect(find.text('₹9,999.00'), findsNothing);
    });

    /// The ledger's net excludes donations, which are counted from their own
    /// register — so it is not the temple's balance, and the public page shows
    /// a different figure. The screen has to say so, or a committee reads the
    /// wrong number out at a meeting (PHASE_9_PLAN assumption N1).
    testWidgets("the figures say they are the ledger's, not the temple's", (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountsScreen(),
        FakeAccountsRepository(transactions: [testTransaction()]),
      );

      expect(
        find.byKey(const Key('accounts-ledger-only-note')),
        findsOneWidget,
      );
      expect(find.text(hi.accountsNet), findsOneWidget);
    });

    testWidgets('an empty register says so', (tester) async {
      await pumpAdmin(
        tester,
        const AdminAccountsScreen(),
        FakeAccountsRepository(),
      );

      expect(find.byKey(const Key('accounts-empty')), findsOneWidget);
    });

    testWidgets('a viewer is not offered the button that records money', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountsScreen(),
        FakeAccountsRepository(transactions: [testTransaction()]),
        permissions: const {Permissions.accountsView},
      );

      expect(find.byKey(const Key('accounts-new')), findsNothing);
    });

    testWidgets('a refusal from the server is shown as one', (tester) async {
      await pumpAdmin(
        tester,
        const AdminAccountsScreen(),
        FakeAccountsRepository(
          listError: const AppException(code: ErrorCode.forbidden),
        ),
      );

      expect(find.text(hi.stateUnauthorizedTitle), findsOneWidget);
    });

    testWidgets('the amount shown is the one the server formatted', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountsScreen(),
        FakeAccountsRepository(
          transactions: [
            testTransaction(
              amountPaise: 12550000,
              amountFormatted: '₹1,25,500.00',
            ),
          ],
        ),
      );

      expect(find.text('₹1,25,500.00'), findsOneWidget);
    });
  });

  group('the editor', () {
    testWidgets('a pending entry says it counts in no total yet', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(transactionId: 1),
        FakeAccountsRepository(transactions: [testTransaction()]),
      );

      expect(find.byKey(const Key('accounts-pending-notice')), findsOneWidget);
      expect(find.byKey(const Key('accounts-approve')), findsOneWidget);
      expect(find.byKey(const Key('accounts-reverse')), findsOneWidget);
    });

    /// The immutability rule, on screen: an approved figure has been counted in
    /// a total the village reads (PHASE_9_PLAN assumption N4).
    testWidgets('an approved entry is locked and says why', (tester) async {
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(transactionId: 1),
        FakeAccountsRepository(
          transactions: [
            testTransaction(
              status: TransactionStatuses.approved,
              isLocked: true,
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('accounts-locked-notice')), findsOneWidget);

      // The amount is not editable; the description still is.
      final amount = tester.widget<TextFormField>(
        find.byKey(const Key('accounts-amount-field')),
      );
      expect(amount.enabled, isFalse);

      final description = tester.widget<TextFormField>(
        find.byKey(const Key('accounts-description-field')),
      );
      expect(description.enabled, isTrue);

      // Approve is gone; reverse — the only undo — remains.
      expect(find.byKey(const Key('accounts-approve')), findsNothing);
      expect(find.byKey(const Key('accounts-reverse')), findsOneWidget);
    });

    testWidgets('a reversed entry offers neither approve nor reverse', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(transactionId: 1),
        FakeAccountsRepository(
          transactions: [
            testTransaction(
              status: TransactionStatuses.reversed,
              reversalReason: 'दो बार दर्ज हो गया था',
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('accounts-reversed-notice')), findsOneWidget);
      expect(find.textContaining('दो बार दर्ज'), findsOneWidget);
      expect(find.byKey(const Key('accounts-approve')), findsNothing);
      expect(find.byKey(const Key('accounts-reverse')), findsNothing);
    });

    testWidgets('approving asks first, and says what it will do', (
      tester,
    ) async {
      final accounts = FakeAccountsRepository(
        transactions: [testTransaction()],
      );
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(transactionId: 1),
        accounts,
      );

      await tester.tap(find.byKey(const Key('accounts-approve')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('accounts-approve-dialog')), findsOneWidget);
      // Nothing has happened yet.
      expect(accounts.approved, isEmpty);

      await tester.tap(find.byKey(const Key('accounts-approve-confirm')));
      await tester.pumpAndSettle();

      expect(accounts.approved, [1]);
    });

    /// The reason is the whole explanation of why a figure that was once
    /// counted no longer is, so the button stays dead until one is written.
    testWidgets('reversing cannot be confirmed without a reason', (
      tester,
    ) async {
      final accounts = FakeAccountsRepository(
        transactions: [testTransaction()],
      );
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(transactionId: 1),
        accounts,
      );

      await tester.tap(find.byKey(const Key('accounts-reverse')));
      await tester.pumpAndSettle();

      final confirm = tester.widget<FilledButton>(
        find.byKey(const Key('accounts-reverse-confirm')),
      );
      expect(confirm.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('accounts-reverse-reason')),
        'गलत श्रेणी में दर्ज',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('accounts-reverse-confirm')));
      await tester.pumpAndSettle();

      expect(accounts.reversalIds, [1]);
      expect(accounts.reversalReasons, ['गलत श्रेणी में दर्ज']);
    });

    testWidgets('the editor says where donations are recorded instead', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(),
        FakeAccountsRepository(),
      );

      expect(
        find.byKey(const Key('accounts-donations-elsewhere')),
        findsOneWidget,
      );
    });

    testWidgets('the bill on a locked entry cannot be replaced', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminTransactionEditorScreen(transactionId: 1),
        FakeAccountsRepository(
          transactions: [
            testTransaction(
              status: TransactionStatuses.approved,
              isLocked: true,
              hasAttachment: true,
            ),
          ],
        ),
      );

      final choose = tester.widget<OutlinedButton>(
        find.byKey(const Key('accounts-choose-bill')),
      );
      expect(choose.onPressed, isNull);

      // But it can still be looked at, which is what auditing is.
      expect(find.byKey(const Key('accounts-view-bill')), findsOneWidget);
    });
  });

  group('the categories', () {
    testWidgets('a used heading has no delete button and explains itself', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountingCategoriesScreen(),
        FakeAccountsRepository(
          categories: [testCategory(id: 7, transactionCount: 4)],
        ),
      );

      expect(find.byKey(const Key('category-row-7')), findsOneWidget);
      expect(find.byKey(const Key('category-usage-7')), findsOneWidget);
      expect(find.byKey(const Key('category-delete-7')), findsNothing);
      expect(find.byKey(const Key('category-edit-7')), findsOneWidget);
    });

    testWidgets('an unused heading may be deleted, after a question', (
      tester,
    ) async {
      final accounts = FakeAccountsRepository(
        categories: [testCategory(id: 3, transactionCount: 0)],
      );
      await pumpAdmin(
        tester,
        const AdminAccountingCategoriesScreen(),
        accounts,
      );

      await tester.tap(find.byKey(const Key('category-delete-3')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category-delete-dialog')), findsOneWidget);
      expect(accounts.deletedCategories, isEmpty);

      await tester.tap(find.byKey(const Key('category-delete-confirm')));
      await tester.pumpAndSettle();

      expect(accounts.deletedCategories, [3]);
    });

    testWidgets('a used heading cannot change side of the books', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountingCategoriesScreen(),
        FakeAccountsRepository(
          categories: [testCategory(id: 7, transactionCount: 4)],
        ),
      );

      await tester.tap(find.byKey(const Key('category-edit-7')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category-in-use-notice')), findsOneWidget);

      final type = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('category-type')),
      );
      expect(type.onChanged, isNull);
    });

    testWidgets('a viewer is offered no way to change a heading', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminAccountingCategoriesScreen(),
        FakeAccountsRepository(categories: [testCategory(id: 3)]),
        permissions: const {Permissions.accountsView},
      );

      expect(find.byKey(const Key('category-new')), findsNothing);
      expect(find.byKey(const Key('category-edit-3')), findsNothing);
      expect(find.byKey(const Key('category-delete-3')), findsNothing);
    });
  });

  group('the settings', () {
    testWidgets('an unpublished ledger says so, with the consequence spelled '
        'out beneath the switch', (tester) async {
      await pumpAdmin(
        tester,
        const AdminAccountingSettingsScreen(),
        FakeAccountsRepository(),
      );

      expect(find.byKey(const Key('accounts-published-chip')), findsOneWidget);
      expect(find.text(hi.accountsBooksAreNotPublic), findsOneWidget);
      expect(find.byKey(const Key('accounts-publish-help')), findsOneWidget);
    });

    testWidgets('publishing the books is a deliberate save', (tester) async {
      final accounts = FakeAccountsRepository();
      await pumpAdmin(tester, const AdminAccountingSettingsScreen(), accounts);

      await tester.tap(find.byKey(const Key('accounts-publish-switch')));
      await tester.pumpAndSettle();

      // Flipping the switch alone sends nothing.
      expect(accounts.lastSettingsDraft, isNull);

      await tester.tap(find.byKey(const Key('accounts-settings-save')));
      await tester.pumpAndSettle();

      expect(accounts.lastSettingsDraft?.isPublished, isTrue);
    });

    testWidgets('a viewer cannot publish the books', (tester) async {
      await pumpAdmin(
        tester,
        const AdminAccountingSettingsScreen(),
        FakeAccountsRepository(),
        permissions: const {Permissions.accountsView},
      );

      final save = tester.widget<FilledButton>(
        find.byKey(const Key('accounts-settings-save')),
      );
      expect(save.onPressed, isNull);

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('accounts-publish-switch')),
      );
      expect(switchTile.onChanged, isNull);
    });
  });
}
