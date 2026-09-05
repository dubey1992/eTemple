import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/report.dart';
import '../domain/reports_repository.dart';
import 'reports_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(appConfigProvider),
  ),
);

/// What this account may run.
final reportCatalogueProvider = FutureProvider<ReportCatalogue>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(reportsRepositoryProvider).catalogue(language: language);
});

/// One report, run.
final reportProvider = FutureProvider.family<ReportData, ReportQuery>((
  ref,
  query,
) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(reportsRepositoryProvider).report(query, language: language);
});

/// The dashboard's figures.
final overviewProvider = FutureProvider<Overview>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(reportsRepositoryProvider).overview(language: language);
});

/// The filters a report is being viewed with, held per report key so switching
/// between two reports and back does not lose either one's period.
class ReportViewController extends Notifier<Map<String, ReportQuery>> {
  @override
  Map<String, ReportQuery> build() => const {};

  ReportQuery queryFor(String key) => state[key] ?? ReportQuery(key: key);

  void update(ReportQuery query) {
    state = {...state, query.key: query};
  }
}

final reportViewProvider =
    NotifierProvider<ReportViewController, Map<String, ReportQuery>>(
      ReportViewController.new,
    );
