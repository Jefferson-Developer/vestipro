import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/price_list.dart';
import '../repositories/price_list_local_store_repository.dart';
import '../repositories/price_list_repository.dart';

/// Prepares the on-device Price List cache (TASK-083's local store, wired
/// here by TASK-107) so pricing keeps working — reading whatever tables the
/// device already has — while the sales rep is offline.
///
/// Unlike `LoadInitialCustomerOfflineDataUseCase`, [PriceListRepository]
/// exposes every non-soft-deleted Price List for a company in a single
/// [PriceListRepository.listByCompany] call (no pagination), so this is a
/// full, idempotent replace in one round trip rather than a page loop: the
/// entire company's pricing reference set is cached, not pre-filtered to
/// "currently applicable" ones, so `ResolveApplicablePriceListsUseCase` can
/// resolve applicability offline exactly the same way it does online, just
/// reading from the local cache instead of Firestore.
@injectable
class LoadInitialPriceListOfflineDataUseCase {
  const LoadInitialPriceListOfflineDataUseCase(
    this._priceListRepository,
    this._localStoreRepository,
  );

  final PriceListRepository _priceListRepository;
  final PriceListLocalStoreRepository _localStoreRepository;

  Future<AppResult<int>> call({
    required String organizationId,
    required String companyId,
  }) async {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedCompanyId = companyId.trim();
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<int>(
        ValidationFailure(
          'Invalid price list offline load payload.',
          code: 'invalid_price_list_offline_load_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final listResult = await _priceListRepository.listByCompany(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
    );
    if (listResult case AppFailure<List<PriceList>>(failure: final failure)) {
      return AppFailure<int>(failure);
    }
    final priceLists = (listResult as AppSuccess<List<PriceList>>).value;

    final replaceResult = await _localStoreRepository.replaceInitialLoad(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
      priceLists: priceLists,
    );
    if (replaceResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<int>(failure);
    }

    return AppSuccess<int>(priceLists.length);
  }
}
