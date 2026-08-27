import '../value_objects/warehouse_type.dart';

/// Inventory unit that serves one company and optionally one branch.
///
/// `branchId == null` models the documented "centralized warehouse"
/// relationship, allowing one warehouse to serve multiple branches (1:N from
/// warehouse to branch coverage) without duplicating the stock entity itself.
final class Warehouse {
  const Warehouse({
    required this.id,
    required this.organizationId,
    required this.companyId,
    this.branchId,
    required this.code,
    required this.name,
    required this.type,
    required this.isActive,
    required this.priority,
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
  final String companyId;
  final String? branchId;
  final String code;
  final String name;
  final WarehouseType type;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  bool get isDeleted => deletedAt != null;

  Warehouse copyWith({
    String? branchId,
    String? code,
    String? name,
    WarehouseType? type,
    bool? isActive,
    int? priority,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    int? version,
    String? syncStatus,
    bool clearBranchId = false,
    bool clearDeletedAt = false,
  }) {
    return Warehouse(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      branchId: clearBranchId ? null : branchId ?? this.branchId,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
