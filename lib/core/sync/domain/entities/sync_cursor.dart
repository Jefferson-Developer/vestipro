import '../../../offline/domain/entities/offline_package_entity_kind.dart';

/// One entity's incremental pull bookmark (TASK-109, EPIC-14) — the
/// domain-level view of `SyncCursorsTable`.
final class SyncCursor {
  const SyncCursor({
    required this.organizationId,
    required this.companyId,
    required this.kind,
    required this.cursorValue,
    required this.updatedAt,
  });

  final String organizationId;
  final String companyId;
  final OfflinePackageEntityKind kind;

  /// Opaque value only the matching `SyncPullSource` interprets — `null`
  /// means this entity has never been pulled incrementally yet for this
  /// scope.
  final String? cursorValue;

  final DateTime updatedAt;
}
