import '../value_objects/ean.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/product_variant_status.dart';
import '../value_objects/sku.dart';
import '../value_objects/variant_availability_status.dart';

/// Sellable SKU generated from one product + one color + one size (TASK-072).
final class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.organizationId,
    required this.productId,
    required this.colorId,
    required this.sizeGridTemplateId,
    required this.sizeId,
    required this.sku,
    this.ean,
    this.manualAvailabilityStatus,
    this.manualAvailableQuantity,
    this.manualFutureAvailableAt,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String organizationId;
  final String productId;
  final String colorId;
  final String sizeGridTemplateId;
  final String sizeId;
  final Sku sku;
  final Ean? ean;
  final VariantAvailabilityStatus? manualAvailabilityStatus;
  final int? manualAvailableQuantity;
  final DateTime? manualFutureAvailableAt;
  final ProductVariantStatus status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
  final ProductSyncStatus syncStatus;

  bool get isActive => status == ProductVariantStatus.active;

  String get combinationKey => '$productId|$colorId|$sizeId';

  ProductVariant copyWith({
    Sku? sku,
    Ean? ean,
    VariantAvailabilityStatus? manualAvailabilityStatus,
    int? manualAvailableQuantity,
    DateTime? manualFutureAvailableAt,
    ProductVariantStatus? status,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
    ProductSyncStatus? syncStatus,
    bool clearEan = false,
    bool clearManualAvailabilityStatus = false,
    bool clearManualAvailableQuantity = false,
    bool clearManualFutureAvailableAt = false,
  }) {
    return ProductVariant(
      id: id,
      organizationId: organizationId,
      productId: productId,
      colorId: colorId,
      sizeGridTemplateId: sizeGridTemplateId,
      sizeId: sizeId,
      sku: sku ?? this.sku,
      ean: clearEan ? null : ean ?? this.ean,
      manualAvailabilityStatus: clearManualAvailabilityStatus
          ? null
          : manualAvailabilityStatus ?? this.manualAvailabilityStatus,
      manualAvailableQuantity: clearManualAvailableQuantity
          ? null
          : manualAvailableQuantity ?? this.manualAvailableQuantity,
      manualFutureAvailableAt: clearManualFutureAvailableAt
          ? null
          : manualFutureAvailableAt ?? this.manualFutureAvailableAt,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
