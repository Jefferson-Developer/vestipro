import 'package:injectable/injectable.dart';

import '../../../../core/offline/offline.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/customer_local_store_repository.dart';
import '../usecases/load_initial_customer_offline_data_use_case.dart';

/// Adapts [LoadInitialCustomerOfflineDataUseCase] (TASK-054) to
/// [OfflinePackageEntityLoader] so `DownloadOfflinePackageUseCase`
/// (TASK-107) can include the Customer portfolio in the offline package
/// download the same way it handles every other entity.
///
/// Always applicable: RBAC/carteira filtering already happens inside
/// [LoadInitialCustomerOfflineDataUseCase] itself (a `SALES_REP` with no
/// active portfolio assignment, or an inactive membership, correctly ends up
/// with an empty — not skipped — local cache), so this loader never needs to
/// decide up front whether the user "has" the entity at all.
@lazySingleton
final class CustomerOfflinePackageEntityLoader
    implements OfflinePackageEntityLoader {
  const CustomerOfflinePackageEntityLoader(
    this._loadInitialCustomerOfflineData,
    this._localStoreRepository,
  );

  final LoadInitialCustomerOfflineDataUseCase _loadInitialCustomerOfflineData;
  final CustomerLocalStoreRepository _localStoreRepository;

  @override
  OfflinePackageEntityKind get kind => OfflinePackageEntityKind.customers;

  @override
  Future<AppResult<bool>> isApplicable({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    return const AppSuccess<bool>(true);
  }

  @override
  Future<AppResult<int>> estimate({
    required String organizationId,
    required String companyId,
    required String userId,
  }) {
    // Best-effort heuristic: how many customers the local cache already
    // holds from a previous load. There is no cheap remote "count" endpoint
    // for the portfolio, and fetching every page just to count them would
    // defeat the point of an "estimate before downloading" step.
    return _localStoreRepository.count(
      organizationId: organizationId,
      companyId: companyId,
    );
  }

  @override
  Future<AppResult<OfflinePackageEntityLoadResult>> load({
    required String organizationId,
    required String companyId,
    required String userId,
    required OfflinePackageCancellationToken cancellationToken,
    required void Function(int recordsFetchedSoFar) onProgress,
    DateTime? now,
  }) async {
    final result = await _loadInitialCustomerOfflineData(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      cancellationToken: cancellationToken,
      onPageFetched: onProgress,
      now: now,
    );
    return result.fold(
      onSuccess: (summary) => AppSuccess<OfflinePackageEntityLoadResult>(
        OfflinePackageEntityLoadResult(
          outcome: summary.cancelled
              ? OfflinePackageEntityLoadOutcome.cancelled
              : OfflinePackageEntityLoadOutcome.completed,
          recordCount: summary.cancelled ? 0 : summary.downloadedCount,
        ),
      ),
      onFailure: AppFailure<OfflinePackageEntityLoadResult>.new,
    );
  }
}
