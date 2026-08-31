import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/offline_package_entity_kind.dart';
import '../../domain/entities/offline_package_entity_status.dart';
import '../../domain/repositories/offline_package_status_repository.dart';

/// Drift-backed implementation of [OfflinePackageStatusRepository]
/// (TASK-107), mirroring `DriftPriceListLocalStoreRepository`/
/// `DriftCustomerLocalStoreRepository`.
@LazySingleton(as: OfflinePackageStatusRepository)
final class DriftOfflinePackageStatusRepository
    implements OfflinePackageStatusRepository {
  const DriftOfflinePackageStatusRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<void>> markIncomplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required DateTime now,
  }) async {
    try {
      await _database.markOfflinePackageEntityIncomplete(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: kind.code,
        now: now,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking offline package entity as incomplete.',
          code: 'offline_package_status_mark_incomplete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> markComplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required int recordCount,
    required DateTime now,
  }) async {
    try {
      await _database.markOfflinePackageEntityComplete(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: kind.code,
        recordCount: recordCount,
        now: now,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking offline package entity as complete.',
          code: 'offline_package_status_mark_complete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<OfflinePackageEntityStatus>>> getAll({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final rows = await _database.getOfflinePackageStatuses(
        organizationId: organizationId,
        companyId: companyId,
      );
      final statuses = <OfflinePackageEntityStatus>[];
      for (final row in rows) {
        final kind = OfflinePackageEntityKindCode.fromCode(row.entityKind);
        if (kind == null) {
          // A row written by a future app version with a kind this build
          // does not know about yet — skip it rather than crash.
          continue;
        }
        statuses.add(
          OfflinePackageEntityStatus(
            kind: kind,
            isComplete: row.isComplete,
            lastCompletedAt: row.lastCompletedAt,
            recordCount: row.recordCount,
          ),
        );
      }
      return AppSuccess<List<OfflinePackageEntityStatus>>(statuses);
    } catch (exception) {
      return AppFailure<List<OfflinePackageEntityStatus>>(
        UnexpectedFailure(
          'Unexpected error loading offline package entity statuses.',
          code: 'offline_package_status_get_all_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
