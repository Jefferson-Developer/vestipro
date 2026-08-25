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

  List<SizeGridSize> get orderedSizes =>
      List<SizeGridSize>.of(sizes)..sort(_compareSizes);

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

  static int _compareSizes(SizeGridSize a, SizeGridSize b) {
    final byScore = a.orderScore.compareTo(b.orderScore);
    if (byScore != 0) return byScore;
    return a.label.compareTo(b.label);
  }
}
