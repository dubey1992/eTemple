import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_container.dart';
import '../../media/presentation/widgets/media_picker_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../content/data/content_providers.dart';
import '../data/event_providers.dart';
import '../domain/event.dart';
import 'event_formatting.dart';

/// Creates or edits one calendar entry.
///
/// The recurrence controls are the heart of it: a repeating event is entered
/// once, so the daily aarti is a single record rather than 365 of them. The day
/// picker only appears for a weekly rule, because that is the only rule it
/// means anything for.
class AdminEventEditorScreen extends ConsumerWidget {
  const AdminEventEditorScreen({super.key, this.eventId});

  final int? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = eventId;
    if (id == null) return const _EventForm(event: null);

    final event = ref.watch(adminEventProvider(id));

    return event.when(
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
          onRetry: () => ref.invalidate(adminEventProvider(id)),
        );
      },
      data: (data) => _EventForm(event: data),
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({required this.event});

  final AdminEvent? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;

  late String _type;
  late String _status;
  late String _recurrence;
  late Set<int> _days;
  late DateTime _startAt;
  DateTime? _endAt;
  late bool _isFeatured;

  bool _saving = false;
  AppException? _error;

  bool get _isNew => widget.event == null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _fields = {
      'title_hi': TextEditingController(text: e?.titleHi ?? ''),
      'title_en': TextEditingController(text: e?.titleEn ?? ''),
      'description_hi': TextEditingController(text: e?.descriptionHi ?? ''),
      'description_en': TextEditingController(text: e?.descriptionEn ?? ''),
      'venue_hi': TextEditingController(text: e?.venueHi ?? ''),
      'venue_en': TextEditingController(text: e?.venueEn ?? ''),
      'poster_url': TextEditingController(text: e?.posterUrl ?? ''),
      'recurrence_until': TextEditingController(text: e?.recurrenceUntil ?? ''),
    };

    _type = e?.eventType ?? EventTypes.puja;
    // A new event starts as a draft: publishing is a deliberate act.
    _status = e?.status ?? EventStatuses.draft;
    _recurrence = e?.recurrence ?? Recurrences.none;
    _days = {...?e?.recurrenceDays};
    _startAt =
        e?.startAt ??
        DateTime.now()
            .add(const Duration(days: 1))
            .copyWith(
              hour: 18,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
    _endAt = e?.endAt;
    _isFeatured = e?.isFeatured ?? false;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pick({required bool isStart}) async {
    final initial = isStart ? _startAt : (_endAt ?? _startAt);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startAt = picked;
      } else {
        _endAt = picked;
      }
    });
  }

  EventDraft _draft() => EventDraft(
    eventType: _type,
    titleHi: _fields['title_hi']!.text,
    titleEn: _fields['title_en']!.text,
    descriptionHi: _fields['description_hi']!.text,
    descriptionEn: _fields['description_en']!.text,
    venueHi: _fields['venue_hi']!.text,
    venueEn: _fields['venue_en']!.text,
    startAt: _startAt,
    endAt: _endAt,
    recurrence: _recurrence,
    recurrenceDays: _days.toList()..sort(),
    recurrenceUntil: _fields['recurrence_until']!.text,
    posterUrl: _fields['poster_url']!.text,
    isFeatured: _isFeatured,
    status: _status,
  );

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      final event = widget.event;

      if (event == null) {
        await repository.createEvent(_draft());
      } else {
        await repository.saveEvent(event.id, _draft());
        ref.invalidate(adminEventProvider(event.id));
      }

      _refreshLists();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event == null
                  ? context.l10n.eventCreated
                  : context.l10n.saveSuccess,
            ),
          ),
        );
        context.go(RoutePaths.adminEvents);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final event = widget.event;
    if (event == null || _saving) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('event-delete-dialog'),
        title: Text(l10n.eventDeleteConfirmTitle),
        content: Text(l10n.eventDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('event-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(eventRepositoryProvider).deleteEvent(event.id);
      _refreshLists();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.eventDeleted)));
        context.go(RoutePaths.adminEvents);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The admin list is filtered four ways and the public pages read the same
  /// records, so every view of them is refreshed rather than just this one.
  void _refreshLists() {
    for (final status in <String?>[
      null,
      EventStatuses.published,
      EventStatuses.draft,
      EventStatuses.cancelled,
    ]) {
      ref.invalidate(adminEventsProvider(status));
    }
    ref.invalidate(eventsProvider);
    ref.invalidate(featuredEventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);
    // Watched, not read: the session resolves after the first build.
    final canEdit = ref
        .watch(permissionsProvider)
        .can(Permissions.eventsManage);
    final enabled = canEdit && !_saving;

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? l10n.eventCreate : l10n.eventEdit,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.hindiRequiredHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!canEdit) ...[
                Container(
                  key: const Key('event-read-only'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    l10n.stateUnauthorizedBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_error != null) ...[
                Container(
                  key: const Key('event-error'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!.localizedMessage(l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      // A refusal against a date or a switch has no text field
                      // to attach itself to; without this it would be reduced
                      // to the generic "there is an error in what you entered".
                      for (final message in _errorsWithoutAField())
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              DropdownButtonFormField<String>(
                key: const Key('event-type'),
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.fieldEventType),
                items: [
                  for (final type in EventTypes.all)
                    DropdownMenuItem(
                      // Keyed so a test can choose an option without tapping
                      // its translated label.
                      key: Key('event-type-$type'),
                      value: type,
                      child: Text(EventFormatting.typeLabel(type, l10n)),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _type = value ?? _type)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              _field(
                'title_hi',
                '${l10n.fieldEventTitle} (हिन्दी)',
                enabled,
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _field(
                'title_en',
                '${l10n.fieldEventTitle} (English) · ${l10n.fieldOptional}',
                enabled,
              ),
              _field(
                'venue_hi',
                '${l10n.fieldVenue} (हिन्दी) · ${l10n.fieldOptional}',
                enabled,
              ),
              _field(
                'venue_en',
                '${l10n.fieldVenue} (English) · ${l10n.fieldOptional}',
                enabled,
              ),
              _field(
                'description_hi',
                '${l10n.fieldEventDescription} (हिन्दी) · ${l10n.fieldOptional}',
                enabled,
                lines: 5,
              ),
              _field(
                'description_en',
                '${l10n.fieldEventDescription} (English) · ${l10n.fieldOptional}',
                enabled,
                lines: 5,
              ),

              const SizedBox(height: AppSpacing.sm),
              _DateTimeField(
                fieldKey: const Key('event-start-at'),
                label: l10n.fieldStartAt,
                value: _stamp(_startAt, language),
                error: _error?.firstErrorFor('start_at'),
                onPick: enabled ? () => _pick(isStart: true) : null,
              ),
              _DateTimeField(
                fieldKey: const Key('event-end-at'),
                label: '${l10n.fieldEndAt} · ${l10n.fieldOptional}',
                value: _endAt == null ? '—' : _stamp(_endAt!, language),
                error: _error?.firstErrorFor('end_at'),
                onPick: enabled ? () => _pick(isStart: false) : null,
                onClear: enabled && _endAt != null
                    ? () => setState(() => _endAt = null)
                    : null,
                clearTooltip: l10n.clearEndTime,
              ),

              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('event-recurrence'),
                initialValue: _recurrence,
                decoration: InputDecoration(labelText: l10n.fieldRecurrence),
                items: [
                  for (final recurrence in Recurrences.all)
                    DropdownMenuItem(
                      key: Key('event-recurrence-$recurrence'),
                      value: recurrence,
                      child: Text(
                        EventFormatting.recurrenceLabel(recurrence, l10n),
                      ),
                    ),
                ],
                onChanged: enabled
                    ? (value) =>
                          setState(() => _recurrence = value ?? _recurrence)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.recurringHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Only meaningful for a weekly rule, so it only appears for one.
              if (_recurrence == Recurrences.weekly) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.fieldRecurrenceDays,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (var day = 1; day <= 7; day++)
                        FilterChip(
                          key: Key('event-day-$day'),
                          label: Text(EventFormatting.weekdayLabel(day, l10n)),
                          selected: _days.contains(day),
                          onSelected: enabled
                              ? (selected) => setState(() {
                                  selected ? _days.add(day) : _days.remove(day);
                                })
                              : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_recurrence != Recurrences.none)
                _field(
                  'recurrence_until',
                  '${l10n.fieldRecurrenceUntil} · ${l10n.dateHint}',
                  enabled,
                ),

              // Chosen from the gallery since Phase 5. It is still stored as
              // a URL, so an externally hosted poster remains possible and
              // Phase 4's records are undisturbed.
              MediaPickerField(
                fieldKey: const ValueKey('event-poster_url'),
                controller: _fields['poster_url']!,
                label: '${l10n.fieldPosterUrl} · ${l10n.fieldOptional}',
                enabled: enabled,
                errorText: _error?.firstErrorFor('poster_url'),
                onChanged: () => setState(() {}),
              ),

              DropdownButtonFormField<String>(
                key: const Key('event-status'),
                initialValue: _status,
                decoration: InputDecoration(labelText: l10n.fieldStatus),
                items: [
                  for (final status in EventStatuses.all)
                    DropdownMenuItem(
                      key: Key('event-status-$status'),
                      value: status,
                      child: Text(EventFormatting.statusLabel(status, l10n)),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _status = value ?? _status)
                    : null,
              ),

              SwitchListTile(
                key: const Key('event-featured'),
                contentPadding: EdgeInsets.zero,
                value: _isFeatured,
                onChanged: enabled
                    ? (v) => setState(() => _isFeatured = v)
                    : null,
                title: Text(l10n.fieldFeatured),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (canEdit) ...[
                    Expanded(
                      child: FilledButton(
                        key: const Key('event-save'),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.actionSave),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.go(RoutePaths.adminEvents),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),

              if (canEdit && !_isNew) ...[
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('event-delete'),
                    onPressed: _saving ? null : _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      l10n.eventDelete,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  /// Server field errors for anything that is not one of the text inputs — the
  /// dates, the type, the status and the featured switch.
  List<String> _errorsWithoutAField() {
    final fieldErrors = _error?.fieldErrors;
    if (fieldErrors == null) return const [];

    return [
      for (final entry in fieldErrors.entries)
        if (!_fields.containsKey(entry.key) &&
            entry.key != 'start_at' &&
            entry.key != 'end_at')
          for (final message in entry.value) message,
    ];
  }

  static String _stamp(DateTime value, String language) =>
      '${EventFormatting.date(value, language)}'
      ' · ${EventFormatting.time(value, language)}';

  Widget _field(
    String name,
    String label,
    bool enabled, {
    TextInputType? keyboardType,
    int lines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('event-$name'),
        controller: _fields[name],
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: lines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}

/// A read-only field that opens the date and time pickers.
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onPick,
    this.error,
    this.onClear,
    this.clearTooltip,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final String? error;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        key: fieldKey,
        onTap: onPick,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            suffixIcon: onClear == null
                ? const Icon(Icons.event_outlined)
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear),
                    tooltip: clearTooltip,
                  ),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}
