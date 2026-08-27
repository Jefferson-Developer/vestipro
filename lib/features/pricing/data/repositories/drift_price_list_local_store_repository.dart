import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/price_list.dart';
import '../../domain/repositories/price_list_local_store_repository.dart';
import '../mappers/price_list_local_mapper.dart';

/// Drift-backed implementation of [PriceListLocalStoreRepository]
/// (TASK-083), mirroring [DriftCustomerLocalStoreRepository] (TASK-054).
@LazySingleton(as: PriceListLocalStoreRepository)
final class DriftPriceListLocalStoreRepository
    implements PriceListLocalStoreRepository {
  const DriftPriceListLocalStoreRepository(this._database, this._mapper);

  final AppDatabase _database;
  final PriceListLocalMapper _mapper;

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PriceList> priceLists,
  }) async {
    try {
      final rows = priceLists.map(_mapper.toRow).toList(growable: false);
      await _database.replacePriceLists(
        organizationId: organizationId,
        companyId: companyId,
        priceListRows: rows,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error replacing local price list offline load.',
          code: 'price_list_offline_load_replace_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> upsert({required PriceList priceList}) async {
    try {
      await _database.upsertPriceList(_mapper.toRow(priceList));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error upserting local price list.',
          code: 'price_list_offline_upsert_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PriceList>>> getAll({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final rows = await _database.getPriceListsForCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<PriceList>>(
        rows.map(_mapper.fromRow).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PriceList>>(
        UnexpectedFailure(
          'Unexpected error loading local price list offline cache.',
          code: 'price_list_offline_load_read_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final total = await _database.countPriceListsForCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<int>(total);
    } catch (exception) {
      return AppFailure<int>(
        UnexpectedFailure(
          'Unexpected error counting local price list offline cache.',
          code: 'price_list_offline_load_count_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
