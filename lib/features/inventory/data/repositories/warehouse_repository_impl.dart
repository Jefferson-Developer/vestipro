import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../datasources/warehouse_remote_data_source.dart';
import '../mappers/warehouse_local_mapper.dart';
import '../mappers/warehouse_mapper.dart';
import '../../../../core/database/database.dart';

@LazySingleton(as: WarehouseRepository)
final class WarehouseRepositoryImpl implements WarehouseRepository {
  const WarehouseRepositoryImpl(
    this._remote,
    this._database,
    this._mapper,
    this._localMapper,
  );

  final WarehouseRemoteDataSource _remote;
  final AppDatabase _database;
  final WarehouseMapper _mapper;
  final WarehouseLocalMapper _localMapper;

  @override
  Future<AppResult<List<Warehouse>>> listByCompany({
    required String organizationId,
    required String companyId,
    String? branchId,
  }) async {
    try {
      final remoteRows = await _remote.listByCompany(
        organizationId: organizationId,
        companyId: companyId,
        branchId: branchId,
      );
      final warehouses = remoteRows
          .map(_mapper.toEntity)
          .toList(growable: false);
      await _database.replaceWarehouses(
        organizationId: organizationId,
        companyId: companyId,
        warehouseRows: warehouses
            .map(_localMapper.toRow)
            .toList(growable: false),
      );
      return AppSuccess<List<Warehouse>>(warehouses);
    } on AppException catch (exception) {
      return _fallbackToLocal(
        organizationId: organizationId,
        companyId: companyId,
        branchId: branchId,
        exception: exception,
      );
    } catch (exception) {
      return _fallbackToLocal(
        organizationId: organizationId,
        companyId: companyId,
        branchId: branchId,
        exception: UnexpectedFailure(
          'Unexpected error loading warehouses.',
          code: 'warehouse_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Warehouse>>> listActive({
    required String organizationId,
    required String companyId,
    String? branchId,
  }) async {
    final result = await listByCompany(
      organizationId: organizationId,
      companyId: companyId,
      branchId: branchId,
    );
    return switch (result) {
      AppSuccess<List<Warehouse>>(value: final warehouses) =>
        AppSuccess<List<Warehouse>>(
          warehouses
              .where((warehouse) => warehouse.isActive && !warehouse.isDeleted)
              .toList(growable: false),
        ),
      AppFailure<List<Warehouse>>(failure: final failure) =>
        AppFailure<List<Warehouse>>(failure),
    };
  }

  Future<AppResult<List<Warehouse>>> _fallbackToLocal({
    required String organizationId,
    required String companyId,
    required Object exception,
    String? branchId,
  }) async {
    try {
      final rows = await _database.getWarehousesByCompany(
        organizationId: organizationId,
        companyId: companyId,
        branchId: branchId,
      );
      final warehouses = rows.map(_localMapper.fromRow).toList(growable: false);
      if (warehouses.isNotEmpty) {
        return AppSuccess<List<Warehouse>>(warehouses);
      }
    } catch (_) {
      // Preserve the original remote failure below.
    }

    final failure = exception is AppFailure
        ? exception.failure
        : exception is Failure
        ? exception
        : exception is AppException
        ? mapAppExceptionToFailure(exception)
        : exception as Failure;
    return AppFailure<List<Warehouse>>(failure);
  }
}
