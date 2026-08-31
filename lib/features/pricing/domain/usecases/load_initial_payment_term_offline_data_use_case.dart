import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/payment_term.dart';
import '../repositories/payment_term_local_store_repository.dart';
import '../repositories/payment_term_repository.dart';

/// Prepares the on-device Payment Term cache so order pricing/checkout keeps
/// offering the same payment conditions while the sales rep is offline
/// (TASK-107), mirroring [LoadInitialPriceListOfflineDataUseCase]: a single
/// full replace from [PaymentTermRepository.listByCompany] (no pagination,
/// no pre-filtering by "active"/"compatible with price list" — that
/// resolution stays with [ListActivePaymentTermsUseCase], applied the same
/// way online or offline).
@injectable
class LoadInitialPaymentTermOfflineDataUseCase {
  const LoadInitialPaymentTermOfflineDataUseCase(
    this._paymentTermRepository,
    this._localStoreRepository,
  );

  final PaymentTermRepository _paymentTermRepository;
  final PaymentTermLocalStoreRepository _localStoreRepository;

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
          'Invalid payment term offline load payload.',
          code: 'invalid_payment_term_offline_load_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final listResult = await _paymentTermRepository.listByCompany(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
    );
    if (listResult case AppFailure<List<PaymentTerm>>(failure: final failure)) {
      return AppFailure<int>(failure);
    }
    final paymentTerms = (listResult as AppSuccess<List<PaymentTerm>>).value;

    final replaceResult = await _localStoreRepository.replaceInitialLoad(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
      paymentTerms: paymentTerms,
    );
    if (replaceResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<int>(failure);
    }

    return AppSuccess<int>(paymentTerms.length);
  }
}
