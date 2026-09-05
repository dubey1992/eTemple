import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/accounts_providers.dart';
import '../domain/account.dart';

/// Whether the temple's books are public, and where they start.
///
/// Two decisions live here and both are the kind that should never be made by
/// accident, which is why the switch says in plain words what turning it on
/// does — and what it will never do, which is name anybody.
class AdminAccountingSettingsScreen extends ConsumerStatefulWidget {
  const AdminAccountingSettingsScreen({super.key});

  @override
  ConsumerState<AdminAccountingSettingsScreen> createState() =>
      _AdminAccountingSettingsScreenState();
}

class _AdminAccountingSettingsScreenState
    extends ConsumerState<AdminAccountingSettingsScreen> {
  final _openingBalance = TextEditingController();
  final _introHi = TextEditingController();
  final _introEn = TextEditingController();
  final _noteHi = TextEditingController();
  final _noteEn = TextEditingController();

  bool _published = false;
  DateTime? _openingDate;
  bool _loaded = false;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _openingBalance.dispose();
    _introHi.dispose();
    _introEn.dispose();
    _noteHi.dispose();
    _noteEn.dispose();
    super.dispose();
  }

  /// Fills the form from the server's copy, once — re-seeding on every rebuild
  /// would discard what the committee had typed.
  void _seed(AccountingSettings settings) {
    if (_loaded) return;
    _loaded = true;

    _openingBalance.text = (settings.openingBalancePaise / 100).toStringAsFixed(
      2,
    );
    _introHi.text = settings.introHi ?? '';
    _introEn.text = settings.introEn ?? '';
    _noteHi.text = settings.noteHi ?? '';
    _noteEn.text = settings.noteEn ?? '';
    _published = settings.isPublished;
    _openingDate = settings.openingBalanceDate == null
        ? null
        : DateTime.tryParse(settings.openingBalanceDate!);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(accountingSettingsProvider);

    return settings.when(
      loading: () => const LoadingView(),
      error: (error, _) {
        final exception = error is AppException
            ? error
            : const AppException.unknown();
        if (exception.code == ErrorCode.forbidden) {
          return const UnauthorizedView();
        }
        return ErrorView(
          error: exception,
          onRetry: () => ref.invalidate(accountingSettingsProvider),
        );
      },
      data: (data) {
        _seed(data);
        return _form(context);
      },
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.accountsManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountsSettingsTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.accountsSettingsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                key: const Key('accounts-published-chip'),
                label: _published
                    ? l10n.accountsBooksArePublic
                    : l10n.accountsBooksAreNotPublic,
                tone: _published ? StatusTone.positive : StatusTone.neutral,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      key: const Key('accounts-publish-switch'),
                      contentPadding: EdgeInsets.zero,
                      value: _published,
                      onChanged: canManage
                          ? (value) => setState(() => _published = value)
                          : null,
                      title: Text(l10n.accountsPublishBooks),
                    ),
                    // The consequence in full, beneath the switch: what appears,
                    // and — the part a committee worries about — what never
                    // does.
                    Text(
                      l10n.accountsPublishBooksHelp,
                      key: const Key('accounts-publish-help'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('accounts-opening-balance'),
              controller: _openingBalance,
              enabled: canManage,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.accountsOpeningBalance,
                prefixText: '₹ ',
                helperText: l10n.accountsOpeningBalanceHelp,
                helperMaxLines: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            InkWell(
              key: const Key('accounts-opening-date'),
              onTap: canManage
                  ? () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _openingDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _openingDate = picked);
                      }
                    }
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.accountsOpeningBalanceDate,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  enabled: canManage,
                ),
                child: Text(
                  _openingDate == null
                      ? '—'
                      : _openingDate!.toIso8601String().split('T').first,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Both languages, stored independently. An absent English value
            // falls back to the Hindi on read and is never filled in with a
            // copy of it.
            TextField(
              key: const Key('accounts-intro-hi'),
              controller: _introHi,
              enabled: canManage,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.accountsIntroHi,
                helperText: l10n.accountsIntroHelp,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('accounts-intro-en'),
              controller: _introEn,
              enabled: canManage,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.accountsIntroEn),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('accounts-note-hi'),
              controller: _noteHi,
              enabled: canManage,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.accountsNoteHi),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('accounts-note-en'),
              controller: _noteEn,
              enabled: canManage,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.accountsNoteEn),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                key: const Key('accounts-settings-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],

            if (_saved) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.saveSuccess,
                key: const Key('accounts-settings-saved'),
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('accounts-settings-save'),
                onPressed: canManage && !_saving ? _save : null,
                child: Text(l10n.actionSave),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });

    try {
      await ref
          .read(accountsRepositoryProvider)
          .saveSettings(
            AccountingSettingsDraft(
              isPublished: _published,
              openingBalance: _openingBalance.text.trim(),
              openingBalanceDate: _openingDate
                  ?.toIso8601String()
                  .split('T')
                  .first,
              introHi: _introHi.text.trim(),
              introEn: _introEn.text.trim(),
              noteHi: _noteHi.text.trim(),
              noteEn: _noteEn.text.trim(),
            ),
          );

      ref.invalidate(accountingSettingsProvider);
      // The public page reads the same row, so it has to be refetched too:
      // otherwise a committee member who just published would open the site and
      // still see "not published".
      ref.invalidate(transparencyProvider);

      if (mounted) setState(() => _saved = true);
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _error = error.localizedMessage(context.l10n));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
