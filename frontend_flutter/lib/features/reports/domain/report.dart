/// Reads a number that may have arrived as an int, a double or a string.
int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

/// How a report column's values should be read, mirroring
/// `App\Reports\ReportColumn`.
class ReportColumnTypes {
  const ReportColumnTypes._();

  static const String text = 'text';

  /// Integer paise. The screen shows the server's formatted string; only the
  /// server ever divides by a hundred.
  static const String money = 'money';

  static const String number = 'number';
  static const String date = 'date';
  static const String datetime = 'datetime';

  static bool isNumeric(String type) => type == money || type == number;
}

/// One column of a report.
class ReportColumn {
  const ReportColumn({
    required this.key,
    required this.label,
    required this.type,
    required this.personal,
  });

  factory ReportColumn.fromJson(Map<String, dynamic> json) => ReportColumn(
    key: _text(json['key']) ?? '',
    label: _text(json['label']) ?? '',
    type: _text(json['type']) ?? ReportColumnTypes.text,
    personal: json['personal'] == true,
  );

  final String key;
  final String label;
  final String type;

  /// True for a column carrying somebody's name, telephone number or address.
  /// Such a column is **absent** from the response unless it was asked for and
  /// allowed — this flag describes what arrived, not what was withheld.
  final bool personal;

  bool get isNumeric => ReportColumnTypes.isNumeric(type);
}

/// A figure above the rows.
class ReportFigure {
  const ReportFigure({
    required this.key,
    required this.label,
    required this.type,
    required this.display,
    this.value,
  });

  factory ReportFigure.fromJson(Map<String, dynamic> json) => ReportFigure(
    key: _text(json['key']) ?? '',
    label: _text(json['label']) ?? '',
    type: _text(json['type']) ?? ReportColumnTypes.text,
    display: _text(json['display']) ?? '—',
    value: json['value'],
  );

  final String key;
  final String label;
  final String type;

  /// What the panel prints. Money arrives already grouped the Indian way.
  final String display;

  /// The raw figure, for anything that needs to compare rather than print.
  final Object? value;
}

/// One cell, as the API sent it.
///
/// Money arrives as a pair — the paise and the string — so the screen can
/// print one and sort by the other without ever doing the division itself.
class ReportCell {
  const ReportCell({this.display, this.paise});

  factory ReportCell.fromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return ReportCell(
        display: _text(value['display']),
        paise: _asInt(value['paise']),
      );
    }

    if (value == null) return const ReportCell();

    return ReportCell(display: value.toString());
  }

  final String? display;
  final int? paise;

  bool get isEmpty => display == null || display!.isEmpty;
}

/// One entry in the catalogue.
class ReportListing {
  const ReportListing({
    required this.key,
    required this.title,
    required this.description,
    required this.hasPersonalColumns,
    required this.maySeePersonal,
  });

  factory ReportListing.fromJson(Map<String, dynamic> json) => ReportListing(
    key: _text(json['key']) ?? '',
    title: _text(json['title']) ?? '',
    description: _text(json['description']) ?? '',
    hasPersonalColumns: json['has_personal_columns'] == true,
    maySeePersonal: json['may_see_personal'] == true,
  );

  final String key;
  final String title;
  final String description;

  /// Whether this report *has* columns that name a person — so the screen can
  /// offer the switch rather than hiding the possibility.
  final bool hasPersonalColumns;

  /// Whether this account may turn that switch on.
  final bool maySeePersonal;
}

/// The catalogue, and what may be done with it.
class ReportCatalogue {
  const ReportCatalogue({
    required this.reports,
    required this.mayExport,
    required this.formats,
    required this.exportLimit,
  });

  factory ReportCatalogue.fromJson(Map<String, dynamic> json) {
    final reports = json['reports'];
    final formats = json['formats'];

    return ReportCatalogue(
      reports: reports is List
          ? reports
                .whereType<Map<String, dynamic>>()
                .map(ReportListing.fromJson)
                .toList(growable: false)
          : const [],
      mayExport: json['may_export'] == true,
      formats: formats is List
          ? formats.whereType<String>().toList(growable: false)
          : const [],
      exportLimit: _asInt(json['export_limit']) ?? 0,
    );
  }

  /// Only what this account may run: the server filtered the list, so the
  /// console never offers a door that will not open.
  final List<ReportListing> reports;

  /// Reading and downloading are separate permissions — a Viewer may read a
  /// report on screen and not take a copy away.
  final bool mayExport;

  final List<String> formats;
  final int exportLimit;
}

/// One report, run.
class ReportData {
  const ReportData({
    required this.key,
    required this.title,
    required this.description,
    required this.columns,
    required this.rows,
    required this.summary,
    required this.filters,
    required this.includesPersonal,
    required this.hasPersonalColumns,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  factory ReportData.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic>? meta,
  ) {
    final columns = json['columns'];
    final rows = json['rows'];
    final summary = json['summary'];
    final filters = json['filters'];

    final parsedColumns = columns is List
        ? columns
              .whereType<Map<String, dynamic>>()
              .map(ReportColumn.fromJson)
              .toList(growable: false)
        : <ReportColumn>[];

    return ReportData(
      key: _text(json['key']) ?? '',
      title: _text(json['title']) ?? '',
      description: _text(json['description']) ?? '',
      columns: parsedColumns,
      rows: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(
                  (row) => {
                    for (final column in parsedColumns)
                      column.key: ReportCell.fromJson(row[column.key]),
                  },
                )
                .toList(growable: false)
          : const [],
      summary: summary is List
          ? summary
                .whereType<Map<String, dynamic>>()
                .map(ReportFigure.fromJson)
                .toList(growable: false)
          : const [],
      filters: filters is List
          ? filters.whereType<String>().toList(growable: false)
          : const [],
      includesPersonal: json['includes_personal'] == true,
      hasPersonalColumns: json['has_personal_columns'] == true,
      currentPage: _asInt(meta?['current_page']) ?? 1,
      lastPage: _asInt(meta?['last_page']) ?? 1,
      total: _asInt(meta?['total']) ?? 0,
    );
  }

  final String key;
  final String title;
  final String description;
  final List<ReportColumn> columns;
  final List<Map<String, ReportCell>> rows;
  final List<ReportFigure> summary;

  /// The filters this run was made under, in the server's words — the same
  /// sentence the export's header block carries.
  final List<String> filters;

  final bool includesPersonal;
  final bool hasPersonalColumns;

  final int currentPage;
  final int lastPage;
  final int total;

  bool get isEmpty => rows.isEmpty;
}

/// One month of the donation trend.
class TrendPoint {
  const TrendPoint({
    required this.month,
    required this.label,
    required this.totalPaise,
    required this.display,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    month: _text(json['month']) ?? '',
    label: _text(json['label']) ?? '',
    totalPaise: _asInt(json['total_paise']) ?? 0,
    display: _text(json['display']) ?? '',
  );

  final String month;
  final String label;
  final int totalPaise;
  final String display;
}

/// One upcoming occurrence on the dashboard.
class OverviewEvent {
  const OverviewEvent({
    required this.date,
    required this.time,
    required this.title,
    required this.isCancelled,
  });

  factory OverviewEvent.fromJson(Map<String, dynamic> json) => OverviewEvent(
    date: _text(json['date']) ?? '',
    time: _text(json['time']) ?? '',
    title: _text(json['title']) ?? '',
    isCancelled: json['is_cancelled'] == true,
  );

  final String date;
  final String time;
  final String title;

  /// A cancelled occurrence is shown and flagged, not dropped: "the aarti is
  /// off on Tuesday" is the thing somebody opening this needs to know.
  final bool isCancelled;
}

/// The dashboard's figures.
///
/// **A panel this account may not see is absent, not empty.** An absent panel
/// says "not yours"; an empty one says "the temple received nothing", and only
/// one of those is true — so every field here is nullable and the screen omits
/// the block rather than drawing zeros.
class Overview {
  const Overview({
    required this.financialYearLabel,
    this.money,
    this.trend,
    this.enquiriesNew,
    this.enquiriesOpen,
    this.upcomingEvents,
  });

  factory Overview.fromJson(Map<String, dynamic> json) {
    final year = json['financial_year'];
    final money = json['money'];
    final trend = json['donation_trend'];
    final enquiries = json['enquiries'];
    final events = json['upcoming_events'];

    return Overview(
      financialYearLabel: year is Map<String, dynamic>
          ? _text(year['label']) ?? ''
          : '',
      money: money is Map<String, dynamic>
          ? OverviewMoney.fromJson(money)
          : null,
      trend: trend is List
          ? trend
                .whereType<Map<String, dynamic>>()
                .map(TrendPoint.fromJson)
                .toList(growable: false)
          : null,
      enquiriesNew: enquiries is Map<String, dynamic>
          ? _asInt(enquiries['new'])
          : null,
      enquiriesOpen: enquiries is Map<String, dynamic>
          ? _asInt(enquiries['open'])
          : null,
      upcomingEvents: events is List
          ? events
                .whereType<Map<String, dynamic>>()
                .map(OverviewEvent.fromJson)
                .toList(growable: false)
          : null,
    );
  }

  final String financialYearLabel;
  final OverviewMoney? money;
  final List<TrendPoint>? trend;
  final int? enquiriesNew;
  final int? enquiriesOpen;
  final List<OverviewEvent>? upcomingEvents;
}

/// This financial year's money, as the dashboard prints it.
class OverviewMoney {
  const OverviewMoney({
    required this.donationsDisplay,
    required this.totalIncomeDisplay,
    required this.totalExpenseDisplay,
    required this.closingBalanceDisplay,
    required this.donationCount,
    required this.donationsPaise,
    required this.closingBalancePaise,
  });

  factory OverviewMoney.fromJson(Map<String, dynamic> json) => OverviewMoney(
    donationsDisplay: _text(json['donations_display']) ?? '—',
    totalIncomeDisplay: _text(json['total_income_display']) ?? '—',
    totalExpenseDisplay: _text(json['total_expense_display']) ?? '—',
    closingBalanceDisplay: _text(json['closing_balance_display']) ?? '—',
    donationCount: _asInt(json['donation_count']) ?? 0,
    donationsPaise: _asInt(json['donations_paise']) ?? 0,
    closingBalancePaise: _asInt(json['closing_balance_paise']) ?? 0,
  );

  final String donationsDisplay;
  final String totalIncomeDisplay;
  final String totalExpenseDisplay;
  final String closingBalanceDisplay;
  final int donationCount;
  final int donationsPaise;
  final int closingBalancePaise;
}
