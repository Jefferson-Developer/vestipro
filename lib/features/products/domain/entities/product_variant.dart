import '../value_objects/ean.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/product_variant_status.dart';
import '../value_objects/sku.dart';

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
    ProductVariantStatus? status,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
    ProductSyncStatus? syncStatus,
    bool clearEan = false,
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
