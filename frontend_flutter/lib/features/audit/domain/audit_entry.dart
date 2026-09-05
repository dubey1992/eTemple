/// Reads a number that may have arrived as an int, a double or a string.
///
/// JSON numbers cross the wire in whichever shape the encoder chose.
int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

/// One entry of the temple's audit trail, as the Super Admin reading it sees it.
///
/// There is no public counterpart and there is not going to be.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.actionLabel,
    required this.recordedAt,
    this.actorName,
    this.actorRole,
    this.entityType,
    this.entityId,
    this.entityLabel,
    this.before = const {},
    this.after = const {},
    this.context,
    this.ipAddress,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    Map<String, Object?> readMap(String key) {
      final value = json[key];
      return value is Map ? Map<String, Object?>.from(value) : const {};
    }

    return AuditEntry(
      id: _asInt(json['id']) ?? 0,
      action: read('action') ?? '',
      actionLabel: read('action_label') ?? read('action') ?? '',
      // The name is the copy stored on the row, so a deleted account's
      // actions still say who took them.
      actorName: read('actor_name'),
      actorRole: read('actor_role'),
      entityType: read('entity_type'),
      entityId: _asInt(json['entity_id']),
      entityLabel: read('entity_label'),
      before: readMap('before_data'),
      after: readMap('after_data'),
      context: read('context'),
      ipAddress: read('ip_address'),
      recordedAt: DateTime.tryParse(read('created_at') ?? ''),
    );
  }

  final int id;
  final String action;
  final String actionLabel;
  final String? actorName;
  final String? actorRole;
  final String? entityType;
  final int? entityId;
  final String? entityLabel;

  /// Only the fields that changed, and never a password or a token — the
  /// server strips those on the way in.
  final Map<String, Object?> before;
  final Map<String, Object?> after;

  final String? context;
  final String? ipAddress;
  final DateTime? recordedAt;

  bool get hasDiff => before.isNotEmpty || after.isNotEmpty;

  /// Every field named on either side, in a stable order, so a change from a
  /// value to null and back again lines up row for row.
  List<String> get changedFields =>
      <String>{...before.keys, ...after.keys}.toList()..sort();
}

/// One kind of action, for the filter.
class AuditActionOption {
  const AuditActionOption({required this.key, required this.label});

  factory AuditActionOption.fromJson(Map<String, dynamic> json) =>
      AuditActionOption(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? json['key'] as String? ?? '',
      );

  final String key;
  final String label;
}

/// A page of the trail.
class AuditPage {
  const AuditPage({
    required this.entries,
    this.total = 0,
    this.hasMore = false,
  });

  static const AuditPage empty = AuditPage(entries: []);

  final List<AuditEntry> entries;
  final int total;
  final bool hasMore;

  AuditPage followedBy(AuditPage next) => AuditPage(
    entries: [...entries, ...next.entries],
    total: next.total,
    hasMore: next.hasMore,
  );
}
