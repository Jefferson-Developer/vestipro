import 'package:injectable/injectable.dart';

import '../../../../core/offline/offline.dart';
import '../../../../core/permissions/capability.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/price_list_local_store_repository.dart';
import '../usecases/load_initial_price_list_offline_data_use_case.dart';

/// Adapts [LoadInitialPriceListOfflineDataUseCase] to
/// [OfflinePackageEntityLoader] (TASK-107).
///
/// Gated by [Capability.orderCreate] rather than [Capability.priceListManage]
/// on purpose: every role allowed to create/price an order — including a
/// plain `SALES_REP`, who is never granted [Capability.priceListManage] —
/// needs Price Lists available offline to price an order without
/// connectivity. [Capability.priceListManage] stays reserved for the
/// pricing *management* screens (`PaymentTermsPage` and siblings), a
/// separate concern from "may this user read Price Lists at all".
@lazySingleton
final class PriceListOfflinePackageEntityLoader
    implements OfflinePackageEntityLoader {
  const PriceListOfflinePackageEntityLoader(
    this._loadInitialPriceListOfflineData,
    this._localStoreRepository,
    this._permissionService,
  );

  final LoadInitialPriceListOfflineDataUseCase _loadInitialPriceListOfflineData;
  final PriceListLocalStoreRepository _localStoreRepository;
  final PermissionService _permissionService;

  @override
  OfflinePackageEntityKind get kind => OfflinePackageEntityKind.priceLists;

  @override
  Future<AppResult<bool>> isApplicable({
    required String organizationId,
    required String companyId,
    required String userId,
  }) {
    return _permissionService.hasPermission(
      organizationId: organizationId,
      userId: userId,
      capability: Capability.orderCreate,
    );
  }

  @override
  Future<AppResult<int>> estimate({
    required String organizationId,
    required String companyId,
    required String userId,
  }) {
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
    if (cancellationToken.isCancelled) {
      return const AppSuccess<OfflinePackageEntityLoadResult>(
        OfflinePackageEntityLoadResult(
          outcome: OfflinePackageEntityLoadOutcome.cancelled,
          recordCount: 0,
        ),
      );
    }

    final result = await _loadInitialPriceListOfflineData(
      organizationId: organizationId,
      companyId: companyId,
    );
    return result.fold(
      onSuccess: (count) {
        onProgress(count);
        return AppSuccess<OfflinePackageEntityLoadResult>(
          OfflinePackageEntityLoadResult(
            outcome: OfflinePackageEntityLoadOutcome.completed,
            recordCount: count,
          ),
        );
      },
      onFailure: AppFailure<OfflinePackageEntityLoadResult>.new,
    );
  }
}
