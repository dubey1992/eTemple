import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_repository.dart';
import 'audit_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The filters the screen is showing.
final auditFilterProvider = NotifierProvider<AuditFilter, AuditQuery>(
  AuditFilter.new,
);

class AuditFilter extends Notifier<AuditQuery> {
  @override
  AuditQuery build() => const AuditQuery();

  /// Explicit nulls really clear a filter: `copyWith` uses a sentinel rather
  /// than `??`, which is the trap that has cost this project three afternoons.
  void selectAction(String? action) =>
      state = state.copyWith(action: action, page: 1);

  void selectWindow({String? from, String? to}) =>
      state = state.copyWith(from: from, to: to, page: 1);

  void clear() => state = const AuditQuery();
}

/// One page of the trail.
final auditEntriesProvider = FutureProvider.family<AuditPage, AuditQuery>(
  (ref, query) => ref.watch(auditRepositoryProvider).entries(query),
);

/// The action vocabulary, for the filter.
final auditActionsProvider = FutureProvider<List<AuditActionOption>>(
  (ref) => ref.watch(auditRepositoryProvider).actions(),
);
