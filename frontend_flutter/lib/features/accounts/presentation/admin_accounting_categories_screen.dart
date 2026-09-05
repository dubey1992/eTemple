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
import 'account_labels.dart';

/// The headings the temple's books are filed under.
///
/// The rule this screen exists to make visible: **a heading that has been used
/// can be closed but not deleted, and cannot move from income to expenditure.**
/// Either would rewrite what old entries mean, silently, in figures that have
/// already been published. So a used category shows its count, loses its delete
/// button and locks its side of the books, with the reason written out.
class AdminAccountingCategoriesScreen extends ConsumerWidget {
  const AdminAccountingCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categories = ref.watch(accountingCategoriesProvider);
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.accountsManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountsCategoriesTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.accountsCategoriesSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  FilledButton.icon(
                    key: const Key('category-new'),
                    onPressed: () => _edit(context, ref, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.accountsCategoryNew),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            categories.when(
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
                  onRetry: () => ref.invalidate(accountingCategoriesProvider),
                );
              },
              data: (all) => all.isEmpty
                  ? EmptyView(
                      key: const Key('categories-empty'),
                      message: l10n.accountsCategoryEmpty,
                      icon: Icons.label_outline,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final type in TransactionTypes.all) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.md,
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              AccountLabels.type(l10n, type),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          for (final category in all.where(
                            (c) => c.type == type,
                          ))
                            _CategoryRow(
                              category: category,
                              canManage: canManage,
                              onEdit: () => _edit(context, ref, category),
                              onDelete: () => _delete(context, ref, category),
                            ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AccountingCategory? category,
  ) async {
    final draft = await showDialog<AccountingCategoryDraft>(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
    if (draft == null) return;

    final repository = ref.read(accountsRepositoryProvider);

    try {
      if (category == null) {
        await repository.createCategory(draft);
      } else {
        await repository.saveCategory(category.id, draft);
      }
      ref.invalidate(accountingCategoriesProvider);
      ref.invalidate(activeCategoriesProvider);
    } on AppException catch (error) {
      if (context.mounted) _tell(context, error);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AccountingCategory category,
  ) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('category-delete-dialog'),
        title: Text(l10n.accountsCategoryDeleteTitle),
        content: Text(l10n.accountsCategoryDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('category-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accountsCategoryDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(accountsRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(accountingCategoriesProvider);
      ref.invalidate(activeCategoriesProvider);
    } on AppException catch (error) {
      // The server refuses a heading that is in use and says how many entries
      // are in the way. That sentence is worth showing verbatim.
      if (context.mounted) _tell(context, error);
    }
  }

  void _tell(BuildContext context, AppException error) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(error.localizedMessage(context.l10n))),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountingCategory category;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final count = category.transactionCount ?? 0;

    return Card(
      key: Key('category-row-${category.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.nameFor(language),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.accountsCategoryUsage(count),
                    key: Key('category-usage-${category.id}'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: category.isActive
                  ? l10n.accountsCategoryActive
                  : l10n.accountsCategoryInactive,
              tone: category.isActive
                  ? StatusTone.positive
                  : StatusTone.neutral,
            ),
            if (canManage) ...[
              IconButton(
                key: Key('category-edit-${category.id}'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.accountsCategoryEdit,
              ),
              // A used heading has no delete button at all, rather than one
              // that produces a refusal. The tooltip on the disabled state
              // would be the only place the reason lived.
              if (!category.isInUse)
                IconButton(
                  key: Key('category-delete-${category.id}'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.accountsCategoryDelete,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final AccountingCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameHi;
  late final TextEditingController _nameEn;
  late String _type;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameHi = TextEditingController(text: category?.nameHi ?? '');
    _nameEn = TextEditingController(text: category?.nameEn ?? '');
    _type = category?.type ?? TransactionTypes.expense;
    _active = category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameHi.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final inUse = widget.category?.isInUse ?? false;

    return AlertDialog(
      key: const Key('category-dialog'),
      title: Text(
        widget.category == null
            ? l10n.accountsCategoryNew
            : l10n.accountsCategoryEdit,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hindi is the source language and is required; English is
              // optional and falls back to it on read.
              TextField(
                key: const Key('category-name-hi'),
                controller: _nameHi,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.accountsCategoryNameHi,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('category-name-en'),
                controller: _nameEn,
                decoration: InputDecoration(
                  labelText: l10n.accountsCategoryNameEn,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                key: const Key('category-type'),
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: l10n.accountsFieldCategory,
                ),
                items: [
                  for (final type in TransactionTypes.all)
                    DropdownMenuItem(
                      value: type,
                      child: Text(AccountLabels.type(l10n, type)),
                    ),
                ],
                // Locked once the heading has been used: flipping it would move
                // every historical entry to the other side of the books.
                onChanged: inUse
                    ? null
                    : (value) => setState(
                        () => _type = value ?? TransactionTypes.expense,
                      ),
              ),

              if (inUse) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.accountsCategoryInUseNotice,
                  key: const Key('category-in-use-notice'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                key: const Key('category-active'),
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                title: Text(
                  _active
                      ? l10n.accountsCategoryActive
                      : l10n.accountsCategoryInactive,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('category-save'),
          onPressed: _nameHi.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  AccountingCategoryDraft(
                    type: _type,
                    nameHi: _nameHi.text.trim(),
                    nameEn: _nameEn.text.trim(),
                    isActive: _active,
                  ),
                ),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
