import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_custom_field_definition.dart';
import '../../domain/entities/product_custom_field_value.dart';
import '../../domain/entities/product_media.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/product_custom_field_type.dart';
import '../../domain/value_objects/product_gender.dart';
import '../../domain/value_objects/product_media_type.dart';
import '../../domain/value_objects/product_status.dart';
import '../../domain/value_objects/product_sync_status.dart';
import '../../domain/value_objects/sku.dart';
import '../../domain/value_objects/target_audience.dart';
import '../dtos/product_custom_field_definition_dto.dart';
import '../dtos/product_dto.dart';
import '../dtos/product_media_dto.dart';

@lazySingleton
final class ProductMapper {
  const ProductMapper();

  Product toEntity(ProductDto dto) {
    return Product(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      sku: Sku.parse(dto.sku),
      reference: dto.reference,
      name: dto.name,
      shortDescription: dto.shortDescription,
      fullDescription: dto.fullDescription,
      brand: dto.brand,
      collectionId: dto.collectionId,
      seasonId: dto.seasonId,
      line: dto.line,
      categoryId: dto.categoryId,
      subcategoryId: dto.subcategoryId,
      gender: dto.gender == null ? null : genderToEntity(dto.gender!),
      targetAudience: dto.targetAudience == null
          ? null
          : targetAudienceToEntity(dto.targetAudience!),
      fabric: dto.fabric,
      composition: dto.composition,
      supplierId: dto.supplierId,
      ncm: dto.ncm,
      ean: dto.ean == null ? null : Ean.parse(dto.ean!),
      tags: dto.tags,
      status: statusToEntity(dto.status),
      launchDate: dto.launchDate,
      seoTitle: dto.seoTitle,
      seoDescription: dto.seoDescription,
      seoSlug: dto.seoSlug,
      media: dto.media.map(_mediaToEntity).toList(growable: false),
      customFieldValues: dto.customFieldValues
          .map(_customFieldValueToEntity)
          .toList(growable: false),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      version: dto.version,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  ProductDto toDto(Product entity) {
    return ProductDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      sku: entity.sku.value,
      reference: entity.reference,
      name: entity.name,
      shortDescription: entity.shortDescription,
      fullDescription: entity.fullDescription,
      brand: entity.brand,
      collectionId: entity.collectionId,
      seasonId: entity.seasonId,
      line: entity.line,
      categoryId: entity.categoryId,
      subcategoryId: entity.subcategoryId,
      gender: entity.gender == null ? null : genderToDto(entity.gender!),
      targetAudience: entity.targetAudience == null
          ? null
          : targetAudienceToDto(entity.targetAudience!),
      fabric: entity.fabric,
      composition: entity.composition,
      supplierId: entity.supplierId,
      ncm: entity.ncm,
      ean: entity.ean?.digits,
      tags: entity.tags,
      status: statusToDto(entity.status),
      launchDate: entity.launchDate,
      seoTitle: entity.seoTitle,
      seoDescription: entity.seoDescription,
      seoSlug: entity.seoSlug,
      media: entity.media.map(_mediaToDto).toList(growable: false),
      customFieldValues: entity.customFieldValues
          .map(_customFieldValueToDto)
          .toList(growable: false),
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
      version: entity.version,
      syncStatus: syncStatusToDto(entity.syncStatus),
    );
  }

  ProductCustomFieldDefinition definitionToEntity(
    ProductCustomFieldDefinitionDto dto,
  ) {
    return ProductCustomFieldDefinition(
      id: dto.id,
      organizationId: dto.organizationId,
      key: dto.key,
      label: dto.label,
      type: customFieldTypeToEntity(dto.type),
      isRequired: dto.isRequired,
      options: dto.options,
    );
  }

  ProductCustomFieldDefinitionDto definitionToDto(
    ProductCustomFieldDefinition entity,
  ) {
    return ProductCustomFieldDefinitionDto(
      id: entity.id,
      organizationId: entity.organizationId,
      key: entity.key,
      label: entity.label,
      type: customFieldTypeToDto(entity.type),
      isRequired: entity.isRequired,
      options: entity.options,
    );
  }

  ProductGender genderToEntity(String value) {
    return switch (value) {
      'masculine' => ProductGender.masculine,
      'feminine' => ProductGender.feminine,
      'unisex' => ProductGender.unisex,
      _ => throw ValidationException(
        'Invalid product gender.',
        code: 'invalid_product_gender',
        cause: value,
      ),
    };
  }

  String genderToDto(ProductGender gender) {
    return switch (gender) {
      ProductGender.masculine => 'masculine',
      ProductGender.feminine => 'feminine',
      ProductGender.unisex => 'unisex',
    };
  }

  TargetAudience targetAudienceToEntity(String value) {
    return switch (value) {
      'adult' => TargetAudience.adult,
      'teen' => TargetAudience.teen,
      'kids' => TargetAudience.kids,
      'baby' => TargetAudience.baby,
      _ => throw ValidationException(
        'Invalid product target audience.',
        code: 'invalid_product_target_audience',
        cause: value,
      ),
    };
  }

  String targetAudienceToDto(TargetAudience targetAudience) {
    return switch (targetAudience) {
      TargetAudience.adult => 'adult',
      TargetAudience.teen => 'teen',
      TargetAudience.kids => 'kids',
      TargetAudience.baby => 'baby',
    };
  }

  ProductStatus statusToEntity(String value) {
    return switch (value) {
      'draft' => ProductStatus.draft,
      'active' => ProductStatus.active,
      'inactive' => ProductStatus.inactive,
      'discontinued' => ProductStatus.discontinued,
      _ => throw ValidationException(
        'Invalid product status.',
        code: 'invalid_product_status',
        cause: value,
      ),
    };
  }

  String statusToDto(ProductStatus status) {
    return switch (status) {
      ProductStatus.draft => 'draft',
      ProductStatus.active => 'active',
      ProductStatus.inactive => 'inactive',
      ProductStatus.discontinued => 'discontinued',
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
        'Invalid product sync status.',
        code: 'invalid_product_sync_status',
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

  ProductCustomFieldType customFieldTypeToEntity(String value) {
    return switch (value) {
      'text' => ProductCustomFieldType.text,
      'number' => ProductCustomFieldType.number,
      'boolean' => ProductCustomFieldType.boolean,
      'list' => ProductCustomFieldType.list,
      _ => throw ValidationException(
        'Invalid product custom field type.',
        code: 'invalid_product_custom_field_type',
        cause: value,
      ),
    };
  }

  String customFieldTypeToDto(ProductCustomFieldType type) {
    return switch (type) {
      ProductCustomFieldType.text => 'text',
      ProductCustomFieldType.number => 'number',
      ProductCustomFieldType.boolean => 'boolean',
      ProductCustomFieldType.list => 'list',
    };
  }

  ProductMedia _mediaToEntity(ProductMediaDto dto) {
    return ProductMedia(
      id: dto.id,
      type: mediaTypeToEntity(dto.type),
      url: dto.url,
      thumbnailUrl: dto.thumbnailUrl,
      order: dto.order,
      principal: dto.principal,
      colorId: dto.colorId,
    );
  }

  ProductMediaDto _mediaToDto(ProductMedia entity) {
    return ProductMediaDto(
      id: entity.id,
      type: mediaTypeToDto(entity.type),
      url: entity.url,
      thumbnailUrl: entity.thumbnailUrl,
      order: entity.order,
      principal: entity.principal,
      colorId: entity.colorId,
    );
  }

  ProductMediaType mediaTypeToEntity(String value) {
    return switch (value) {
      'photo' => ProductMediaType.photo,
      'video' => ProductMediaType.video,
      _ => throw ValidationException(
        'Invalid product media type.',
        code: 'invalid_product_media_type',
        cause: value,
      ),
    };
  }

  String mediaTypeToDto(ProductMediaType type) {
    return switch (type) {
      ProductMediaType.photo => 'photo',
      ProductMediaType.video => 'video',
    };
  }

  ProductCustomFieldValue _customFieldValueToEntity(
    ProductCustomFieldValueDto dto,
  ) {
    return ProductCustomFieldValue(
      fieldDefinitionId: dto.fieldDefinitionId,
      value: dto.value,
    );
  }

  ProductCustomFieldValueDto _customFieldValueToDto(
    ProductCustomFieldValue entity,
  ) {
    return ProductCustomFieldValueDto(
      fieldDefinitionId: entity.fieldDefinitionId,
      value: entity.value,
    );
  }
}
