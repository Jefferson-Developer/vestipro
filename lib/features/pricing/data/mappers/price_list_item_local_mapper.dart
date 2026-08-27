import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/price_list_item.dart';

@lazySingleton
final class PriceListItemLocalMapper {
  const PriceListItemLocalMapper();

  PriceListItemsTableCompanion toRow(PriceListItem item) {
    return PriceListItemsTableCompanion.insert(
      id: item.id,
      organizationId: item.organizationId,
      companyId: item.companyId,
      priceListId: item.priceListId,
      productId: item.productId,
      variantId: Value(item.variantId),
      price: item.price,
      updatedAt: item.updatedAt.toUtc(),
      updatedBy: item.updatedBy,
      deletedAt: Value(item.deletedAt?.toUtc()),
      version: Value(item.version),
      syncStatus: Value(item.syncStatus),
    );
  }

  PriceListItem fromRow(PriceListItemsTableData row) {
    return PriceListItem(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      priceListId: row.priceListId,
      productId: row.productId,
      variantId: row.variantId,
      price: row.price,
      updatedAt: row.updatedAt,
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt,
      version: row.version,
      syncStatus: row.syncStatus,
    );
  }
}
