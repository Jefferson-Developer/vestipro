import '../../../../core/utils/utils.dart';
import '../entities/price_list_item.dart';

abstract interface class PriceListItemRepository {
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  });

  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  });

  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  });
}
