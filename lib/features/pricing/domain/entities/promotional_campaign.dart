import '../value_objects/promotional_campaign_status.dart';
import '../value_objects/promotional_discount_type.dart';

final class PromotionalCampaign {
  const PromotionalCampaign({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.name,
    required this.validFrom,
    required this.validTo,
    required this.customerSegment,
    required this.discountType,
    required this.discountValue,
    required this.stackableWithOtherCampaigns,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.productIds = const <String>[],
    this.collectionIds = const <String>[],
    this.categoryIds = const <String>[],
    this.deletedAt,
    this.version = 1,
    this.syncStatus = 'pending',
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String name;
  final DateTime validFrom;
  final DateTime validTo;
  final String customerSegment;
  final List<String> productIds;
  final List<String> collectionIds;
  final List<String> categoryIds;
  final PromotionalDiscountType discountType;
  final double discountValue;
  final bool stackableWithOtherCampaigns;
  final int priority;
  final PromotionalCampaignStatus status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  bool get isActive =>
      status == PromotionalCampaignStatus.active && deletedAt == null;

  bool isValidAt(DateTime instant) {
    final normalized = instant.toUtc();
    return !normalized.isBefore(validFrom.toUtc()) &&
        !normalized.isAfter(validTo.toUtc());
  }

  bool matchesCustomerSegment(String candidateSegment) {
    return customerSegment.trim().toLowerCase() ==
        candidateSegment.trim().toLowerCase();
  }

  bool matchesProduct({
    required String productId,
    String? collectionId,
    String? categoryId,
  }) {
    if (productIds.isEmpty && collectionIds.isEmpty && categoryIds.isEmpty) {
      return true;
    }
    if (productIds.contains(productId.trim())) return true;
    if (collectionId != null && collectionIds.contains(collectionId.trim())) {
      return true;
    }
    if (categoryId != null && categoryIds.contains(categoryId.trim())) {
      return true;
    }
    return false;
  }

  PromotionalCampaign copyWith({
    String? name,
    DateTime? validFrom,
    DateTime? validTo,
    String? customerSegment,
    List<String>? productIds,
    List<String>? collectionIds,
    List<String>? categoryIds,
    PromotionalDiscountType? discountType,
    double? discountValue,
    bool? stackableWithOtherCampaigns,
    int? priority,
    PromotionalCampaignStatus? status,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? syncStatus,
  }) {
    return PromotionalCampaign(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      name: name ?? this.name,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      customerSegment: customerSegment ?? this.customerSegment,
      productIds: productIds ?? this.productIds,
      collectionIds: collectionIds ?? this.collectionIds,
      categoryIds: categoryIds ?? this.categoryIds,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      stackableWithOtherCampaigns:
          stackableWithOtherCampaigns ?? this.stackableWithOtherCampaigns,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toAuditMap() {
    return <String, Object?>{
      'name': name,
      'validFrom': validFrom.toUtc().toIso8601String(),
      'validTo': validTo.toUtc().toIso8601String(),
      'customerSegment': customerSegment,
      'productIds': productIds,
      'collectionIds': collectionIds,
      'categoryIds': categoryIds,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'stackableWithOtherCampaigns': stackableWithOtherCampaigns,
      'priority': priority,
      'status': status.name,
    };
  }
}
