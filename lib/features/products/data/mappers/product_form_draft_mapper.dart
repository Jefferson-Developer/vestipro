import 'package:injectable/injectable.dart';

import '../../domain/entities/product_form_draft.dart';
import '../dtos/product_form_draft_dto.dart';

@lazySingleton
final class ProductFormDraftMapper {
  const ProductFormDraftMapper();

  ProductFormDraft toEntity(ProductFormDraftDto dto) {
    return ProductFormDraft(
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      userId: dto.userId,
      productId: dto.productId,
      name: dto.name,
      sku: dto.sku,
      reference: dto.reference,
      brand: dto.brand,
      categoryId: dto.categoryId,
      subcategoryId: dto.subcategoryId,
      collectionId: dto.collectionId,
      seasonId: dto.seasonId,
      line: dto.line,
      gender: dto.gender,
      targetAudience: dto.targetAudience,
      shortDescription: dto.shortDescription,
      fullDescription: dto.fullDescription,
      tags: dto.tags,
      sizeGridTemplateId: dto.sizeGridTemplateId,
      fabric: dto.fabric,
      composition: dto.composition,
      supplierId: dto.supplierId,
      ncm: dto.ncm,
      ean: dto.ean,
      seoTitle: dto.seoTitle,
      seoDescription: dto.seoDescription,
      seoSlug: dto.seoSlug,
      launchDate: dto.launchDate,
      savedAt: dto.savedAt,
    );
  }

  ProductFormDraftDto toDto(ProductFormDraft entity) {
    return ProductFormDraftDto(
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      userId: entity.userId,
      productId: entity.productId,
      name: entity.name,
      sku: entity.sku,
      reference: entity.reference,
      brand: entity.brand,
      categoryId: entity.categoryId,
      subcategoryId: entity.subcategoryId,
      collectionId: entity.collectionId,
      seasonId: entity.seasonId,
      line: entity.line,
      gender: entity.gender,
      targetAudience: entity.targetAudience,
      shortDescription: entity.shortDescription,
      fullDescription: entity.fullDescription,
      tags: entity.tags,
      sizeGridTemplateId: entity.sizeGridTemplateId,
      fabric: entity.fabric,
      composition: entity.composition,
      supplierId: entity.supplierId,
      ncm: entity.ncm,
      ean: entity.ean,
      seoTitle: entity.seoTitle,
      seoDescription: entity.seoDescription,
      seoSlug: entity.seoSlug,
      launchDate: entity.launchDate,
      savedAt: entity.savedAt,
    );
  }
}
