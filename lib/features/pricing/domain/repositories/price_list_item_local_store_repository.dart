import '../../../../core/utils/utils.dart';
import '../entities/price_list_item.dart';

abstract interface class PriceListItemLocalStoreRepository {
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
  });

  Future<AppResult<void>> upsert({required PriceListItem item});

  Future<AppResult<List<PriceListItem>>> getByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  });
}
