import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/reports/domain/report.dart';
import 'package:rkt_web/features/reports/domain/reports_repository.dart';

/// Scriptable stand-in for the HTTP reports repository.
///
/// **No report is reimplemented here.** What a report contains, which rows a
/// filter matches and what the totals come to are the server's decisions; a
/// fake that computed them would be testing the fake, and would quietly teach
/// the screens that the client may produce a figure. What this does instead is
/// record what was asked for and return whatever the server is being made to
/// say — which is exactly what the export guarantee needs asserting about.
class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository({
    ReportCatalogue? catalogue,
    ReportData? data,
    Overview? overview,
    this.catalogueError,
    this.reportError,
    this.overviewError,
  }) : _catalogue = catalogue ?? testCatalogue(),
       _data = data ?? testReportData(),
       _overview = overview ?? testOverview();

  final ReportCatalogue _catalogue;
  final ReportData _data;
  final Overview _overview;

  AppException? catalogueError;
  AppException? reportError;
  AppException? overviewError;

  ReportQuery? lastQuery;
  String? lastLanguage;

  /// Every export URL this screen produced, so a test can assert that the file
  /// and the screen were asked for with the same filters.
  final List<String> exportUrls = [];

  @override
  Future<ReportCatalogue> catalogue({required String language}) async {
    lastLanguage = language;
    if (catalogueError != null) throw catalogueError!;
    return _catalogue;
  }

  @override
  Future<ReportData> report(
    ReportQuery query, {
    required String language,
  }) async {
    lastQuery = query;
    lastLanguage = language;
    if (reportError != null) throw reportError!;
    return _data;
  }

  @override
  String exportUrl(
    ReportQuery query, {
    required String format,
    required String language,
  }) {
    // The real implementation builds this from the query object; the fake keeps
    // the same shape so a test can read the filters back out of the URL.
    final parameters =
        <String, String>{
            for (final entry in query.toQueryParameters().entries)
              if (entry.value != null) entry.key: '${entry.value}',
            'format': format,
            'lang': language,
          }
          ..remove('page')
          ..remove('per_page');

    final url =
        'https://example.test/api/admin/reports/${query.key}/export'
        '?${parameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    exportUrls.add(url);
    return url;
  }

  @override
  Future<Overview> overview({required String language}) async {
    lastLanguage = language;
    if (overviewError != null) throw overviewError!;
    return _overview;
  }
}

ReportListing testReportListing({
  String key = 'donations',
  String title = 'दान रजिस्टर',
  String description = 'अवधि में दर्ज प्रत्येक दान।',
  bool hasPersonalColumns = true,
  bool maySeePersonal = true,
}) => ReportListing(
  key: key,
  title: title,
  description: description,
  hasPersonalColumns: hasPersonalColumns,
  maySeePersonal: maySeePersonal,
);

ReportCatalogue testCatalogue({
  List<ReportListing>? reports,
  bool mayExport = true,
  int exportLimit = 10000,
}) => ReportCatalogue(
  reports: reports ?? [testReportListing()],
  mayExport: mayExport,
  formats: const ['csv', 'xlsx', 'pdf'],
  exportLimit: exportLimit,
);

ReportData testReportData({
  String key = 'donations',
  String title = 'दान रजिस्टर',
  List<ReportColumn>? columns,
  List<Map<String, ReportCell>>? rows,
  List<ReportFigure>? summary,
  List<String> filters = const ['2026-04-01 – 2027-03-31'],
  bool includesPersonal = false,
  bool hasPersonalColumns = true,
  int total = 1,
}) {
  final resolvedColumns =
      columns ??
      [
        const ReportColumn(
          key: 'donation_date',
          label: 'तिथि',
          type: ReportColumnTypes.date,
          personal: false,
        ),
        const ReportColumn(
          key: 'amount',
          label: 'राशि',
          type: ReportColumnTypes.money,
          personal: false,
        ),
        if (includesPersonal)
          const ReportColumn(
            key: 'donor_name',
            label: 'दानदाता',
            type: ReportColumnTypes.text,
            personal: true,
          ),
      ];

  return ReportData(
    key: key,
    title: title,
    description: 'अवधि में दर्ज प्रत्येक दान।',
    columns: resolvedColumns,
    rows:
        rows ??
        [
          {
            'donation_date': const ReportCell(display: '2026-08-31'),
            'amount': const ReportCell(display: '₹5,000.00', paise: 500000),
            if (includesPersonal)
              'donor_name': const ReportCell(display: 'रामप्रसाद यादव'),
          },
        ],
    summary:
        summary ??
        [
          const ReportFigure(
            key: 'total',
            label: 'कुल प्राप्त',
            type: ReportColumnTypes.money,
            display: '₹5,000.00',
            value: 500000,
          ),
        ],
    filters: filters,
    includesPersonal: includesPersonal,
    hasPersonalColumns: hasPersonalColumns,
    total: total,
  );
}

Overview testOverview({
  OverviewMoney? money,
  List<TrendPoint>? trend,
  int? enquiriesNew = 2,
  int? enquiriesOpen = 3,
  List<OverviewEvent>? upcomingEvents = const [],
}) => Overview(
  financialYearLabel: '2026–27',
  money:
      money ??
      const OverviewMoney(
        donationsDisplay: '₹42,200.00',
        totalIncomeDisplay: '₹53,540.00',
        totalExpenseDisplay: '₹1,02,480.00',
        closingBalanceDisplay: '₹1,01,060.00',
        donationCount: 4,
        donationsPaise: 4220000,
        closingBalancePaise: 10106000,
      ),
  trend:
      trend ??
      [
        for (var month = 1; month <= 12; month++)
          TrendPoint(
            month: '2026-${month.toString().padLeft(2, '0')}',
            label: 'M$month',
            // A couple of empty months on purpose: the chart has to keep them.
            totalPaise: month % 4 == 0 ? 0 : month * 100000,
            display: '₹${month * 1000}.00',
          ),
      ],
  enquiriesNew: enquiriesNew,
  enquiriesOpen: enquiriesOpen,
  upcomingEvents: upcomingEvents,
);
