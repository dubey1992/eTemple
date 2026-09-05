import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/audit/domain/audit_entry.dart';
import 'package:rkt_web/features/audit/domain/audit_repository.dart';

/// An in-memory audit trail for widget tests.
///
/// Read only, like the real one: there is nothing to fake on the write side
/// because there is no write side.
class FakeAuditRepository implements AuditRepository {
  FakeAuditRepository({
    List<AuditEntry>? entries,
    List<AuditActionOption>? actions,
    this.listError,
    this.hasMore = false,
  }) : list = entries ?? const [],
       actionList =
           actions ??
           const [
             AuditActionOption(
               key: 'donation.recorded',
               label: 'दान दर्ज किया / Donation recorded',
             ),
             AuditActionOption(
               key: 'report.exported',
               label: 'रिपोर्ट डाउनलोड की / Report exported',
             ),
           ];

  List<AuditEntry> list;
  List<AuditActionOption> actionList;
  AppException? listError;
  bool hasMore;

  /// The last filters the screen asked for, so a test can assert that choosing
  /// one really reached the repository rather than only changing a dropdown.
  AuditQuery? lastQuery;

  @override
  Future<AuditPage> entries(AuditQuery query) async {
    lastQuery = query;
    if (listError != null) throw listError!;

    final matching = query.action == null
        ? list
        : list.where((entry) => entry.action == query.action).toList();

    return AuditPage(
      entries: matching,
      total: matching.length,
      hasMore: hasMore,
    );
  }

  @override
  Future<List<AuditActionOption>> actions() async => actionList;
}

/// One entry, with sensible defaults.
AuditEntry testAuditEntry({
  int id = 1,
  String action = 'donation.updated',
  String actionLabel = 'दान में सुधार / Donation edited',
  String? actorName = 'त्रिभुवन सिंह',
  String? entityLabel = 'RKT/2026/0007 · रामप्रसाद यादव',
  Map<String, Object?> before = const {},
  Map<String, Object?> after = const {},
  String? context,
  String? ipAddress = '203.0.113.4',
  DateTime? recordedAt,
}) => AuditEntry(
  id: id,
  action: action,
  actionLabel: actionLabel,
  actorName: actorName,
  actorRole: 'treasurer',
  entityType: 'donations',
  entityId: 7,
  entityLabel: entityLabel,
  before: before,
  after: after,
  context: context,
  ipAddress: ipAddress,
  recordedAt: recordedAt ?? DateTime(2026, 9, 15, 10, 30),
);
