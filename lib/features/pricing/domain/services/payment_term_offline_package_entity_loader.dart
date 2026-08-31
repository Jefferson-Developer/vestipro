import 'package:injectable/injectable.dart';

import '../../../../core/offline/offline.dart';
import '../../../../core/permissions/capability.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/payment_term_local_store_repository.dart';
import '../usecases/load_initial_payment_term_offline_data_use_case.dart';

/// Adapts [LoadInitialPaymentTermOfflineDataUseCase] to
/// [OfflinePackageEntityLoader] (TASK-107) — same
/// [Capability.orderCreate] rationale as
/// [PriceListOfflinePackageEntityLoader]: any role that can price/create an
/// order needs Payment Terms offline too.
@lazySingleton
final class PaymentTermOfflinePackageEntityLoader
    implements OfflinePackageEntityLoader {
  const PaymentTermOfflinePackageEntityLoader(
    this._loadInitialPaymentTermOfflineData,
    this._localStoreRepository,
    this._permissionService,
  );

  final LoadInitialPaymentTermOfflineDataUseCase
  _loadInitialPaymentTermOfflineData;
  final PaymentTermLocalStoreRepository _localStoreRepository;
  final PermissionService _permissionService;

  @override
  OfflinePackageEntityKind get kind => OfflinePackageEntityKind.paymentTerms;

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

    final result = await _loadInitialPaymentTermOfflineData(
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
