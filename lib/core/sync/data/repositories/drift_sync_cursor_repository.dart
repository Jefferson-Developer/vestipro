import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../../../errors/errors.dart';
import '../../../offline/domain/entities/offline_package_entity_kind.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/sync_cursor.dart';
import '../../domain/repositories/sync_cursor_repository.dart';

/// Drift-backed implementation of [SyncCursorRepository] (TASK-109),
/// mirroring `DriftOfflinePackageStatusRepository`.
@LazySingleton(as: SyncCursorRepository)
final class DriftSyncCursorRepository implements SyncCursorRepository {
  const DriftSyncCursorRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<SyncCursor?>> getCursor({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
  }) async {
    try {
      final row = await _database.getSyncCursor(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: kind.code,
      );
      if (row == null) return const AppSuccess<SyncCursor?>(null);
      return AppSuccess<SyncCursor?>(
        SyncCursor(
          organizationId: row.organizationId,
          companyId: row.companyId,
          kind: kind,
          cursorValue: row.cursorValue,
          updatedAt: row.updatedAt,
        ),
      );
    } catch (exception) {
      return AppFailure<SyncCursor?>(
        UnexpectedFailure(
          'Unexpected error loading sync cursor.',
          code: 'sync_cursor_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> saveCursor({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required String? cursorValue,
    required DateTime updatedAt,
  }) async {
    try {
      await _database.upsertSyncCursor(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: kind.code,
        cursorValue: cursorValue,
        updatedAt: updatedAt,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving sync cursor.',
          code: 'sync_cursor_save_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
