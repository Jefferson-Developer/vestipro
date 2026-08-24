import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_local_store_repository.dart';
import '../mappers/customer_local_mapper.dart';

/// Drift-backed implementation of [CustomerLocalStoreRepository] (TASK-054).
@LazySingleton(as: CustomerLocalStoreRepository)
final class DriftCustomerLocalStoreRepository
    implements CustomerLocalStoreRepository {
  const DriftCustomerLocalStoreRepository(this._database, this._mapper);

  final AppDatabase _database;
  final CustomerLocalMapper _mapper;

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<Customer> customers,
  }) async {
    try {
      final customerRows = customers
          .map(_mapper.toCustomerRow)
          .toList(growable: false);
      final addressRows = customers
          .expand(_mapper.toAddressRows)
          .toList(growable: false);
      final contactRows = customers
          .expand(_mapper.toContactRows)
          .toList(growable: false);

      await _database.replaceCustomers(
        organizationId: organizationId,
        companyId: companyId,
        customerRows: customerRows,
        addressRows: addressRows,
        contactRows: contactRows,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error replacing local customer offline load.',
          code: 'customer_offline_load_replace_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Customer>>> getAll({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final rows = await _database.getCustomersForCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<Customer>>(
        rows.map(_mapper.fromRow).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<Customer>>(
        UnexpectedFailure(
          'Unexpected error loading local customer offline cache.',
          code: 'customer_offline_load_read_unexpected',
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
      final total = await _database.countCustomersForCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<int>(total);
    } catch (exception) {
      return AppFailure<int>(
        UnexpectedFailure(
          'Unexpected error counting local customer offline cache.',
          code: 'customer_offline_load_count_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
