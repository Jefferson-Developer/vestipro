import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/commercial_pack.dart';
import '../../domain/repositories/commercial_pack_local_store_repository.dart';
import '../mappers/commercial_pack_local_mapper.dart';

/// Drift-backed implementation of [CommercialPackLocalStoreRepository]
/// (TASK-207), mirroring [DriftPriceListLocalStoreRepository] (TASK-083).
@LazySingleton(as: CommercialPackLocalStoreRepository)
final class DriftCommercialPackLocalStoreRepository
    implements CommercialPackLocalStoreRepository {
  const DriftCommercialPackLocalStoreRepository(this._database, this._mapper);

  final AppDatabase _database;
  final CommercialPackLocalMapper _mapper;

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    String? companyId,
    required List<CommercialPack> packs,
  }) async {
    try {
      final rows = packs.map(_mapper.toRow).toList(growable: false);
      await _database.replaceCommercialPacks(
        organizationId: organizationId,
        companyId: companyId,
        packRows: rows,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error replacing local commercial pack offline load.',
          code: 'commercial_pack_offline_load_replace_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> upsert({required CommercialPack pack}) async {
    try {
      await _database.upsertCommercialPack(_mapper.toRow(pack));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error upserting local commercial pack.',
          code: 'commercial_pack_offline_upsert_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<CommercialPack>>> getAll({
    required String organizationId,
    String? companyId,
  }) async {
    try {
      final rows = await _database.getCommercialPacksForOrganization(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<CommercialPack>>(
        rows.map(_mapper.fromRow).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<CommercialPack>>(
        UnexpectedFailure(
          'Unexpected error loading local commercial pack offline cache.',
          code: 'commercial_pack_offline_load_read_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    String? companyId,
  }) async {
    try {
      final total = await _database.countCommercialPacksForOrganization(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<int>(total);
    } catch (exception) {
      return AppFailure<int>(
        UnexpectedFailure(
          'Unexpected error counting local commercial pack offline cache.',
          code: 'commercial_pack_offline_load_count_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
