import 'audit_entry.dart';

/// Reading the audit trail. There is deliberately nothing else on it.
///
/// No create, no update, no delete and no export: the trail is append-only, and
/// it carries donor names and enquiry references, so a downloadable copy of it
/// would be a personal-data leak with an official-sounding name
/// (PHASE_11_PLAN assumption S5).
abstract class AuditRepository {
  Future<AuditPage> entries(AuditQuery query);

  /// The vocabulary, so the filter offers the real list rather than a text box
  /// that matches nothing.
  Future<List<AuditActionOption>> actions();
}

/// The filters, as one value-equal key so a provider family can cache on it.
class AuditQuery {
  const AuditQuery({
    this.action,
    this.entityType,
    this.entityId,
    this.userId,
    this.from,
    this.to,
    this.page = 1,
    this.perPage = 50,
  });

  final String? action;
  final String? entityType;
  final int? entityId;
  final int? userId;

  /// Plain dates. An audit trail is read by day, and a timezone shifting the
  /// boundary is the defect Phase 4 spent a red build finding.
  final String? from;
  final String? to;

  final int page;
  final int perPage;

  AuditQuery copyWith({
    Object? action = _unset,
    Object? from = _unset,
    Object? to = _unset,
    int? page,
  }) => AuditQuery(
    action: action == _unset ? this.action : action as String?,
    entityType: entityType,
    entityId: entityId,
    userId: userId,
    from: from == _unset ? this.from : from as String?,
    to: to == _unset ? this.to : to as String?,
    page: page ?? this.page,
    perPage: perPage,
  );

  /// A sentinel, so `copyWith(action: null)` really clears the filter instead
  /// of falling through to the current value — the `??` trap that has cost
  /// this project three afternoons.
  static const Object _unset = Object();

  Map<String, String> toQueryParameters() => {
    'action': ?action,
    'entity_type': ?entityType,
    if (entityId != null) 'entity_id': '$entityId',
    if (userId != null) 'user_id': '$userId',
    'from': ?from,
    'to': ?to,
    'page': '$page',
    'per_page': '$perPage',
  };

  @override
  bool operator ==(Object other) =>
      other is AuditQuery &&
      other.action == action &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.userId == userId &&
      other.from == from &&
      other.to == to &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode => Object.hash(
    action,
    entityType,
    entityId,
    userId,
    from,
    to,
    page,
    perPage,
  );
}
