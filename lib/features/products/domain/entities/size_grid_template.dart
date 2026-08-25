import '../value_objects/product_sync_status.dart';

/// A single ordered size inside a reusable size-grid template (TASK-071).
///
/// The explicit [orderScore] is the commercial order used by catalog and
/// order grids; callers must never infer order alphabetically from [label].
final class SizeGridSize {
  const SizeGridSize({
    required this.id,
    required this.organizationId,
    required this.label,
    required this.orderScore,
  });

  final String id;
  final String organizationId;
  final String label;
  final int orderScore;

  SizeGridSize copyWith({String? label, int? orderScore}) {
    return SizeGridSize(
      id: id,
      organizationId: organizationId,
      label: label ?? this.label,
      orderScore: orderScore ?? this.orderScore,
    );
  }
}

/// Central commercial ordering comparator for [SizeGridSize] (TASK-075).
///
/// This is the single source of truth for size ordering across the app:
/// every screen or query that lists sizes (grade comercial, formulário de
/// cadastro, relatórios, detalhe de produto) must sort through this
/// comparator — directly or via [SizeGridSizeOrdering.sortedByCommercialOrder]
/// or [SizeGridTemplate.orderedSizes] — instead of reimplementing sorting.
///
/// Sizes are always ordered by the explicit, required [SizeGridSize.orderScore]
/// (e.g. PP=1, P=2, M=3 or 34=1, 36=2, 38=3), never by alphabetical label.
/// The label is used only as a deterministic tie-breaker when two sizes of
/// the same template share the same score — it never substitutes for a
/// missing or inconsistent score, which the data layer must reject outright.
int compareSizeGridSizesByOrder(SizeGridSize a, SizeGridSize b) {
  final byScore = a.orderScore.compareTo(b.orderScore);
  if (byScore != 0) return byScore;
  return a.label.compareTo(b.label);
}

/// Shared extension so any list of [SizeGridSize] can be sorted using the
/// single central commercial-order comparator (TASK-075).
extension SizeGridSizeOrdering on List<SizeGridSize> {
  List<SizeGridSize> sortedByCommercialOrder() =>
      List<SizeGridSize>.of(this)..sort(compareSizeGridSizesByOrder);
}

/// Reusable organization-scoped size grid, associated to many products by id.
final class SizeGridTemplate {
  const SizeGridTemplate({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.sizes,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String organizationId;
  final String name;
  final List<SizeGridSize> sizes;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final ProductSyncStatus syncStatus;

  List<SizeGridSize> get orderedSizes => sizes.sortedByCommercialOrder();

  bool get isDeleted => deletedAt != null;

  SizeGridTemplate copyWith({
    String? name,
    List<SizeGridSize>? sizes,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    int? version,
    ProductSyncStatus? syncStatus,
  }) {
    return SizeGridTemplate(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      sizes: sizes ?? this.sizes,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
