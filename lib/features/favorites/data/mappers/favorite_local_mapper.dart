import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/favorite_product.dart';
import '../../domain/value_objects/favorite_sync_status.dart';

/// Converts between [FavoriteProduct] and [FavoritesTable] rows
/// (TASK-079) — the only place a Drift row type is allowed to leak, exactly
/// like every other `*LocalMapper` in this codebase (`CustomerLocalMapper`,
/// `ProductSearchIndexMapper`).
@injectable
class FavoriteLocalMapper {
  const FavoriteLocalMapper();

  FavoritesTableCompanion toRow(FavoriteProduct favorite) {
    return FavoritesTableCompanion.insert(
      organizationId: favorite.organizationId,
      userId: favorite.userId,
      productId: favorite.productId,
      companyId: Value(favorite.companyId),
      createdAt: favorite.createdAt,
      syncStatus: favorite.syncStatus.name,
    );
  }

  FavoriteProduct fromRow(FavoritesTableData row) {
    return FavoriteProduct(
      productId: row.productId,
      userId: row.userId,
      organizationId: row.organizationId,
      companyId: row.companyId,
      createdAt: row.createdAt,
      syncStatus: _statusFromName(row.syncStatus),
    );
  }

  FavoriteSyncStatus _statusFromName(String name) {
    return FavoriteSyncStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => FavoriteSyncStatus.pending,
    );
  }
}
