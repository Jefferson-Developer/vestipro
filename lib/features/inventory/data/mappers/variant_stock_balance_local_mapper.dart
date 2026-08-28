import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/variant_stock_balance.dart';

@lazySingleton
final class VariantStockBalanceLocalMapper {
  const VariantStockBalanceLocalMapper();

  VariantStockBalancesTableCompanion toRow(VariantStockBalance entity) {
    return VariantStockBalancesTableCompanion.insert(
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
      cacheFetchedAt: entity.cacheFetchedAt,
    );
  }

  VariantStockBalance fromRow(VariantStockBalancesTableData row) {
    return VariantStockBalance(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      productId: row.productId,
      variantId: row.variantId,
      warehouseId: row.warehouseId,
      physicalQuantity: row.physicalQuantity,
      reservedQuantity: row.reservedQuantity,
      blockedQuantity: row.blockedQuantity,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      lastSource: row.lastSource,
      version: row.version,
      cacheFetchedAt: row.cacheFetchedAt,
    );
  }
}
