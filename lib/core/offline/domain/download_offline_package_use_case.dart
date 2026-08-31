import 'package:injectable/injectable.dart';

import '../../errors/errors.dart';
import '../../utils/utils.dart';
import 'entities/offline_package_entity_kind.dart';
import 'entities/offline_package_entity_status.dart';
import 'entities/offline_package_load_summary.dart';
import 'entities/offline_package_progress.dart';
import 'offline_package_cancellation_token.dart';
import 'offline_package_entity_loader.dart';
import 'repositories/offline_package_status_repository.dart';

/// Orchestrates the offline package download (TASK-107, EPIC-14 — seção 5.1
/// de `tasks.md`): resolves which registered [OfflinePackageEntityLoader]s
/// apply to the signed-in user, estimates the total size, then downloads
/// each applicable entity **sequentially**, one full atomic local replace at
/// a time.
///
/// ## Why sequential, one-entity-at-a-time commits
///
/// Each entity's local write is already a single atomic transaction (its
/// `XLocalStoreRepository.replaceInitialLoad`). Running entities
/// sequentially rather than buffering every entity's records in memory
/// before writing anything means: (1) memory only ever holds one entity's
/// in-flight records at a time, never the whole multi-entity package at
/// once; (2) if entity B fails or is cancelled after entity A already
/// committed, A's data stays intact and trustworthy — only B (and anything
/// after it, which never started) is left flagged incomplete.
///
/// ## Cancellation
///
/// [cancellationToken] is checked before every entity starts and forwarded
/// to each loader so it can also check it between its own internal lots
/// (e.g. remote pages). A cancellation observed before an entity's local
/// write starts always leaves that entity — and everything after it —
/// flagged incomplete via [OfflinePackageStatusRepository.markIncomplete];
/// it never rolls back an entity whose write already committed.
///
/// ## Resumability
///
/// Unless [forceFullReload] is `true`, an entity whose status is already
/// [OfflinePackageEntityStatus.isComplete] from a previous run of this same
/// scope is skipped — calling this again after a partial/failed/cancelled
/// run "resumes" at entity granularity by only (re)downloading whatever
/// did not finish last time. True sub-entity resumability (e.g. resuming a
/// single entity's page fetch loop from where it stopped) is out of scope
/// here — the incremental sync engine (TASK-109) is the intended owner of
/// that finer-grained merge behavior, reusing the same local schema.
@injectable
class DownloadOfflinePackageUseCase {
  const DownloadOfflinePackageUseCase(this._loaders, this._statusRepository);

  final List<OfflinePackageEntityLoader> _loaders;
  final OfflinePackageStatusRepository _statusRepository;

  Future<AppResult<OfflinePackageLoadSummary>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    OfflinePackageCancellationToken? cancellationToken,
    void Function(OfflinePackageProgress progress)? onProgress,
    bool forceFullReload = false,
    DateTime? now,
  }) async {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedCompanyId = companyId.trim();
    final normalizedUserId = userId.trim();
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (normalizedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<OfflinePackageLoadSummary>(
        ValidationFailure(
          'Invalid offline package download payload.',
          code: 'invalid_offline_package_download_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final resolvedNow = now ?? DateTime.now().toUtc();
    final token = cancellationToken ?? OfflinePackageCancellationToken();

    // 1. Resolve which registered loaders apply to this user (RBAC).
    final applicableLoaders = <OfflinePackageEntityLoader>[];
    for (final loader in _loaders) {
      final applicableResult = await loader.isApplicable(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        userId: normalizedUserId,
      );
      if (applicableResult case AppFailure<bool>(failure: final failure)) {
        return AppFailure<OfflinePackageLoadSummary>(failure);
      }
      if ((applicableResult as AppSuccess<bool>).value) {
        applicableLoaders.add(loader);
      }
    }

    if (!forceFullReload) {
      final statusesResult = await _statusRepository.getAll(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
      );
      if (statusesResult case AppFailure<List<OfflinePackageEntityStatus>>(
        failure: final failure,
      )) {
        return AppFailure<OfflinePackageLoadSummary>(failure);
      }
      final statuses =
          (statusesResult as AppSuccess<List<OfflinePackageEntityStatus>>)
              .value;
      final completedKinds = statuses
          .where((status) => status.isComplete)
          .map((status) => status.kind)
          .toSet();
      applicableLoaders.removeWhere(
        (loader) => completedKinds.contains(loader.kind),
      );
    }

    // 2. Estimate phase.
    var estimatedTotal = 0;
    for (final loader in applicableLoaders) {
      final estimateResult = await loader.estimate(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        userId: normalizedUserId,
      );
      estimatedTotal += estimateResult.fold(
        onSuccess: (count) => count,
        onFailure: (_) => 0,
      );
    }

    // 3. Download phase — sequential, one entity at a time.
    final entityRecordCounts = <OfflinePackageEntityKind, int>{};
    var processedEntities = 0;
    var processedRecords = 0;

    for (final loader in applicableLoaders) {
      if (token.isCancelled) {
        return AppSuccess<OfflinePackageLoadSummary>(
          OfflinePackageLoadSummary(
            entityRecordCounts: entityRecordCounts,
            cancelled: true,
            completedAt: resolvedNow,
          ),
        );
      }

      onProgress?.call(
        OfflinePackageProgress(
          currentEntity: loader.kind,
          processedEntities: processedEntities,
          totalEntities: applicableLoaders.length,
          processedRecords: processedRecords,
          estimatedTotalRecords: estimatedTotal,
        ),
      );

      final markIncompleteResult = await _statusRepository.markIncomplete(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        kind: loader.kind,
        now: resolvedNow,
      );
      if (markIncompleteResult case AppFailure<void>(failure: final failure)) {
        return AppFailure<OfflinePackageLoadSummary>(failure);
      }

      final loadResult = await loader.load(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        userId: normalizedUserId,
        cancellationToken: token,
        now: resolvedNow,
        onProgress: (recordsFetchedSoFar) {
          onProgress?.call(
            OfflinePackageProgress(
              currentEntity: loader.kind,
              processedEntities: processedEntities,
              totalEntities: applicableLoaders.length,
              processedRecords: processedRecords + recordsFetchedSoFar,
              estimatedTotalRecords: estimatedTotal,
            ),
          );
        },
      );

      if (loadResult case AppFailure<OfflinePackageEntityLoadResult>(
        failure: final failure,
      )) {
        return AppFailure<OfflinePackageLoadSummary>(failure);
      }
      final entityResult =
          (loadResult as AppSuccess<OfflinePackageEntityLoadResult>).value;

      if (entityResult.outcome == OfflinePackageEntityLoadOutcome.cancelled) {
        return AppSuccess<OfflinePackageLoadSummary>(
          OfflinePackageLoadSummary(
            entityRecordCounts: entityRecordCounts,
            cancelled: true,
            completedAt: resolvedNow,
          ),
        );
      }

      final markCompleteResult = await _statusRepository.markComplete(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        kind: loader.kind,
        recordCount: entityResult.recordCount,
        now: resolvedNow,
      );
      if (markCompleteResult case AppFailure<void>(failure: final failure)) {
        return AppFailure<OfflinePackageLoadSummary>(failure);
      }

      entityRecordCounts[loader.kind] = entityResult.recordCount;
      processedEntities += 1;
      processedRecords += entityResult.recordCount;
    }

    onProgress?.call(
      OfflinePackageProgress(
        currentEntity: null,
        processedEntities: processedEntities,
        totalEntities: applicableLoaders.length,
        processedRecords: processedRecords,
        estimatedTotalRecords: estimatedTotal,
      ),
    );

    return AppSuccess<OfflinePackageLoadSummary>(
      OfflinePackageLoadSummary(
        entityRecordCounts: entityRecordCounts,
        cancelled: false,
        completedAt: resolvedNow,
      ),
    );
  }
}
