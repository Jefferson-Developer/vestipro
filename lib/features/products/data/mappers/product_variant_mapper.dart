import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/product_sync_status.dart';
import '../../domain/value_objects/product_variant_status.dart';
import '../../domain/value_objects/sku.dart';
import '../../domain/value_objects/variant_availability_status.dart';
import '../dtos/product_variant_dto.dart';

final class ProductVariantMapper {
  const ProductVariantMapper();

  ProductVariant toEntity(ProductVariantDto dto) {
    return ProductVariant(
      id: dto.id,
      organizationId: dto.organizationId,
      productId: dto.productId,
      colorId: dto.colorId,
      sizeGridTemplateId: dto.sizeGridTemplateId,
      sizeId: dto.sizeId,
      sku: Sku.parse(dto.sku),
      ean: dto.ean == null ? null : Ean.parse(dto.ean!),
      manualAvailabilityStatus: dto.manualAvailabilityStatus == null
          ? null
          : availabilityStatusToEntity(dto.manualAvailabilityStatus!),
      manualAvailableQuantity: dto.manualAvailableQuantity,
      manualFutureAvailableAt: dto.manualFutureAvailableAt?.toUtc(),
      status: statusToEntity(dto.status),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  ProductVariantDto toDto(ProductVariant entity) {
    return ProductVariantDto(
      id: entity.id,
      organizationId: entity.organizationId,
      productId: entity.productId,
      colorId: entity.colorId,
      sizeGridTemplateId: entity.sizeGridTemplateId,
      sizeId: entity.sizeId,
      sku: entity.sku.value,
      ean: entity.ean?.digits,
      manualAvailabilityStatus: entity.manualAvailabilityStatus == null
          ? null
          : availabilityStatusToDto(entity.manualAvailabilityStatus!),
      manualAvailableQuantity: entity.manualAvailableQuantity,
      manualFutureAvailableAt: entity.manualFutureAvailableAt?.toUtc(),
      status: statusToDto(entity.status),
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  ProductVariantStatus statusToEntity(String value) {
    return switch (value) {
      'active' => ProductVariantStatus.active,
      'inactive' => ProductVariantStatus.inactive,
      _ => throw ValidationException(
        'Invalid product variant status.',
        code: 'invalid_product_variant_status',
        cause: value,
      ),
    };
  }

  String statusToDto(ProductVariantStatus status) {
    return switch (status) {
      ProductVariantStatus.active => 'active',
      ProductVariantStatus.inactive => 'inactive',
    };
  }

  VariantAvailabilityStatus availabilityStatusToEntity(String value) {
    return switch (value) {
      'readyStock' => VariantAvailabilityStatus.readyStock,
      'futureStock' => VariantAvailabilityStatus.futureStock,
      'unavailable' => VariantAvailabilityStatus.unavailable,
      _ => throw ValidationException(
        'Invalid product variant availability status.',
        code: 'invalid_product_variant_availability_status',
        cause: value,
      ),
    };
  }

  String availabilityStatusToDto(VariantAvailabilityStatus status) {
    return switch (status) {
      VariantAvailabilityStatus.readyStock => 'readyStock',
      VariantAvailabilityStatus.futureStock => 'futureStock',
      VariantAvailabilityStatus.unavailable => 'unavailable',
    };
  }

  ProductSyncStatus syncStatusToEntity(String value) {
    return switch (value) {
      'pending' => ProductSyncStatus.pending,
      'syncing' => ProductSyncStatus.syncing,
      'synced' => ProductSyncStatus.synced,
      'failed' => ProductSyncStatus.failed,
      'conflict' => ProductSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid product variant sync status.',
        code: 'invalid_product_variant_sync_status',
        cause: value,
      ),
    };
  }

  String syncStatusToDto(ProductSyncStatus status) {
    return switch (status) {
      ProductSyncStatus.pending => 'pending',
      ProductSyncStatus.syncing => 'syncing',
      ProductSyncStatus.synced => 'synced',
      ProductSyncStatus.failed => 'failed',
      ProductSyncStatus.conflict => 'conflict',
    };
  }
}
