import '../value_objects/discount_policy_status.dart';

final class DiscountPolicy {
  const DiscountPolicy({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.role,
    required this.maxDiscountPercent,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.priceListIds = const <String>[],
    this.requiresApprovalAbovePercent,
    this.deletedAt,
    this.version = 1,
    this.syncStatus = 'pending',
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String role;
  final double maxDiscountPercent;
  final List<String> priceListIds;
  final double? requiresApprovalAbovePercent;
  final DiscountPolicyStatus status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  bool get isActive =>
      status == DiscountPolicyStatus.active && deletedAt == null;

  bool appliesToPriceList(String? priceListId) {
    if (priceListIds.isEmpty) return true;
    if (priceListId == null || priceListId.trim().isEmpty) return false;
    return priceListIds.contains(priceListId.trim());
  }

  double get approvalThresholdPercent =>
      requiresApprovalAbovePercent ?? maxDiscountPercent;

  DiscountPolicy copyWith({
    String? id,
    String? organizationId,
    String? companyId,
    String? role,
    double? maxDiscountPercent,
    List<String>? priceListIds,
    double? requiresApprovalAbovePercent,
    bool clearRequiresApprovalAbovePercent = false,
    DiscountPolicyStatus? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? syncStatus,
  }) {
    return DiscountPolicy(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      role: role ?? this.role,
      maxDiscountPercent: maxDiscountPercent ?? this.maxDiscountPercent,
      priceListIds: priceListIds ?? this.priceListIds,
      requiresApprovalAbovePercent: clearRequiresApprovalAbovePercent
          ? null
          : (requiresApprovalAbovePercent ?? this.requiresApprovalAbovePercent),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toAuditMap() {
    return <String, Object?>{
      'role': role,
      'maxDiscountPercent': maxDiscountPercent,
      'priceListIds': priceListIds,
      'requiresApprovalAbovePercent': requiresApprovalAbovePercent,
      'status': status.name,
    };
  }
}
