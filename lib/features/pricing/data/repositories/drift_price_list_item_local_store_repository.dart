import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/price_list_item.dart';
import '../../domain/repositories/price_list_item_local_store_repository.dart';
import '../mappers/price_list_item_local_mapper.dart';

@LazySingleton(as: PriceListItemLocalStoreRepository)
final class DriftPriceListItemLocalStoreRepository
    implements PriceListItemLocalStoreRepository {
  const DriftPriceListItemLocalStoreRepository(this._database, this._mapper);

  final AppDatabase _database;
  final PriceListItemLocalMapper _mapper;

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
  }) async {
    try {
      await _database.replacePriceListItems(
        organizationId: organizationId,
        companyId: companyId,
        priceListId: priceListId,
        itemRows: items.map(_mapper.toRow).toList(growable: false),
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error replacing local price list item offline load.',
          code: 'price_list_item_offline_replace_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> upsert({required PriceListItem item}) async {
    try {
      await _database.upsertPriceListItem(_mapper.toRow(item));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error upserting local price list item.',
          code: 'price_list_item_offline_upsert_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PriceListItem>>> getByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) async {
    try {
      final rows = await _database.getPriceListItemsByPriceList(
        organizationId: organizationId,
        companyId: companyId,
        priceListId: priceListId,
      );
      return AppSuccess<List<PriceListItem>>(
        rows.map(_mapper.fromRow).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PriceListItem>>(
        UnexpectedFailure(
          'Unexpected error loading local price list item cache.',
          code: 'price_list_item_offline_read_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
