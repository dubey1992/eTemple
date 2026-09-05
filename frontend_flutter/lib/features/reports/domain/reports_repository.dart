import 'report.dart';

/// What a report is being asked for.
///
/// **The same object builds the screen's request and the export's URL.** That
/// is the client half of PHASE_10_PLAN assumption N1: the file cannot carry
/// different filters from the screen, because there is only one place the
/// filters are turned into a query string.
class ReportQuery {
  const ReportQuery({
    required this.key,
    this.year,
    this.from,
    this.to,
    this.status,
    this.type,
    this.purpose,
    this.mode,
    this.categoryId,
    this.search,
    this.includePersonal = false,
    this.page = 1,
    this.perPage = 50,
  });

  final String key;

  /// The April an Indian financial year starts in. Null asks for the current
  /// one, which is what a first visit means.
  final int? year;

  /// `YYYY-MM-DD`. When either is set it overrides [year].
  final String? from;
  final String? to;

  final String? status;
  final String? type;
  final String? purpose;
  final String? mode;
  final int? categoryId;
  final String? search;

  /// Off unless somebody asked. Asking without the permission is refused by
  /// the server rather than quietly answered with a narrower file.
  final bool includePersonal;

  final int page;
  final int perPage;

  ReportQuery copyWith({
    int? year,
    String? from,
    String? to,
    String? status,
    String? type,
    String? purpose,
    String? mode,
    int? categoryId,
    String? search,
    bool? includePersonal,
    int? page,
    bool clearDates = false,
  }) => ReportQuery(
    key: key,
    year: year ?? this.year,
    from: clearDates ? null : (from ?? this.from),
    to: clearDates ? null : (to ?? this.to),
    status: status ?? this.status,
    type: type ?? this.type,
    purpose: purpose ?? this.purpose,
    mode: mode ?? this.mode,
    categoryId: categoryId ?? this.categoryId,
    search: search ?? this.search,
    includePersonal: includePersonal ?? this.includePersonal,
    // Every filter change resets to the first page: page four of a filter that
    // now matches two rows is an empty screen with no explanation.
    page: page ?? 1,
    perPage: perPage,
  );

  /// The query string, built once and used by both the screen and the export.
  Map<String, Object?> toQueryParameters() => {
    'year': ?year,
    'from': ?from,
    'to': ?to,
    'status': ?status,
    'type': ?type,
    'purpose': ?purpose,
    'mode': ?mode,
    'category_id': ?categoryId,
    'q': ?search,
    if (includePersonal) 'include_personal': '1',
    'page': page,
    'per_page': perPage,
  };

  // Value equality because this is a provider family key: without it every
  // rebuild would ask for a new provider and refetch the same page.
  @override
  bool operator ==(Object other) =>
      other is ReportQuery &&
      other.key == key &&
      other.year == year &&
      other.from == from &&
      other.to == to &&
      other.status == status &&
      other.type == type &&
      other.purpose == purpose &&
      other.mode == mode &&
      other.categoryId == categoryId &&
      other.search == search &&
      other.includePersonal == includePersonal &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode => Object.hash(
    key,
    year,
    from,
    to,
    status,
    type,
    purpose,
    mode,
    categoryId,
    search,
    includePersonal,
    page,
    perPage,
  );
}

/// Contract for the standard reports and the dashboard's figures.
///
/// There is deliberately **no write method of any kind**: nothing in this
/// module changes anything, and the absence here is the client half of that.
abstract interface class ReportsRepository {
  /// What this account may run. The server filters the list.
  Future<ReportCatalogue> catalogue({required String language});

  /// One report, run with [query].
  Future<ReportData> report(ReportQuery query, {required String language});

  /// The absolute URL of an export, for opening in a new tab.
  ///
  /// Built from the **same** [query] the screen was drawn with, so the file and
  /// the screen cannot carry different filters.
  String exportUrl(
    ReportQuery query, {
    required String format,
    required String language,
  });

  /// The dashboard's figures. Panels the account may not see are absent.
  Future<Overview> overview({required String language});
}
