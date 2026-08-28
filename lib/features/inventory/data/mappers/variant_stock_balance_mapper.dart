import 'package:injectable/injectable.dart';

import '../../domain/entities/variant_stock_balance.dart';
import '../dtos/variant_stock_balance_dto.dart';

@lazySingleton
final class VariantStockBalanceMapper {
  const VariantStockBalanceMapper();

  VariantStockBalance toEntity(
    VariantStockBalanceDto dto, {
    required DateTime cacheFetchedAt,
  }) {
    return VariantStockBalance(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      productId: dto.productId,
      variantId: dto.variantId,
      warehouseId: dto.warehouseId,
      physicalQuantity: dto.physicalQuantity,
      reservedQuantity: dto.reservedQuantity,
      blockedQuantity: dto.blockedQuantity,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      lastSource: dto.lastSource,
      version: dto.version,
      cacheFetchedAt: cacheFetchedAt,
    );
  }

  VariantStockBalanceDto toDto(VariantStockBalance entity) {
    return VariantStockBalanceDto(
      id: entity.id,
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      productId: entity.productId,
      variantId: entity.variantId,
      warehouseId: entity.warehouseId,
      physicalQuantity: entity.physicalQuantity,
      reservedQuantity: entity.reservedQuantity,
      blockedQuantity: entity.blockedQuantity,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      lastSource: entity.lastSource,
      version: entity.version,
    );
  }
}
