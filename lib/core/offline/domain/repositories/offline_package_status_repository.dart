import '../../../utils/utils.dart';
import '../entities/offline_package_entity_kind.dart';
import '../entities/offline_package_entity_status.dart';

/// Domain contract for the on-device "carga completa"/"carga incompleta"
/// marker (TASK-107) `DownloadOfflinePackageUseCase` writes around every
/// entity it downloads and the future Central de Sincronização (TASK-112)
/// is expected to read to tell the user which offline data is currently
/// trustworthy.
abstract interface class OfflinePackageStatusRepository {
  /// Marks [kind] as incomplete for [organizationId]/[companyId] — called
  /// right before an entity's download starts, so an interruption before
  /// [markComplete] runs always leaves the entity flagged as not
  /// trustworthy.
  Future<AppResult<void>> markIncomplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required DateTime now,
  });

  /// Marks [kind] as complete for [organizationId]/[companyId], recording
  /// [recordCount] and [now] — called only after that entity's local
  /// replace transaction has actually committed.
  Future<AppResult<void>> markComplete({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required int recordCount,
    required DateTime now,
  });

  /// Every entity status ever recorded for [organizationId]/[companyId].
  Future<AppResult<List<OfflinePackageEntityStatus>>> getAll({
    required String organizationId,
    required String companyId,
  });
}
