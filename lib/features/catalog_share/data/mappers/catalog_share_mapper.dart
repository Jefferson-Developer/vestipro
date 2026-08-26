import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/catalog_share.dart';
import '../../domain/entities/catalog_share_item.dart';
import '../../domain/entities/catalog_share_preview.dart';
import '../../domain/value_objects/catalog_share_outcome.dart';
import '../../domain/value_objects/catalog_share_scope.dart';
import '../dtos/catalog_share_dto.dart';
import '../dtos/catalog_share_item_dto.dart';
import '../dtos/catalog_share_preview_dto.dart';

@lazySingleton
final class CatalogShareMapper {
  const CatalogShareMapper();

  CatalogShare toEntity(CatalogShareDto dto) {
    return CatalogShare(
      id: dto.id,
      organizationId: dto.organizationId,
      scope: scopeToEntity(dto.scope),
      items: dto.items.map(itemToEntity).toList(growable: false),
      collectionId: dto.collectionId,
      collectionName: dto.collectionName,
      isRevoked: dto.status == 'revoked',
      openCount: dto.openCount,
      firstOpenedAt: dto.firstOpenedAt,
      lastOpenedAt: dto.lastOpenedAt,
      expiresAt: dto.expiresAt,
      createdBy: dto.createdBy,
      createdByName: dto.createdByName,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  CatalogSharePreview previewToEntity(CatalogSharePreviewDto dto) {
    return CatalogSharePreview(
      outcome: outcomeToEntity(dto.outcome),
      organizationName: dto.organizationName,
      scope: dto.scope == null ? null : scopeToEntity(dto.scope!),
      items: dto.items.map(itemToEntity).toList(growable: false),
      collectionName: dto.collectionName,
      expiresAt: dto.expiresAt,
    );
  }

  CatalogShareItem itemToEntity(CatalogShareItemDto dto) {
    return CatalogShareItem(
      productId: dto.productId,
      name: dto.name,
      imageUrl: dto.imageUrl,
    );
  }

  CatalogShareItemDto itemToDto(CatalogShareItem item) {
    return CatalogShareItemDto(
      productId: item.productId,
      name: item.name,
      imageUrl: item.imageUrl,
    );
  }

  CatalogShareScope scopeToEntity(String value) {
    final scope = catalogShareScopeFromCode(value);
    if (scope == null) {
      throw ValidationException(
        'Invalid catalog share scope.',
        code: 'invalid_catalog_share_scope',
        cause: value,
      );
    }
    return scope;
  }

  String scopeToDto(CatalogShareScope scope) => scope.code;

  CatalogShareOutcome outcomeToEntity(String value) {
    final outcome = catalogShareOutcomeFromCode(value);
    if (outcome == null) {
      throw ValidationException(
        'Invalid catalog share outcome.',
        code: 'invalid_catalog_share_outcome',
        cause: value,
      );
    }
    return outcome;
  }
}
