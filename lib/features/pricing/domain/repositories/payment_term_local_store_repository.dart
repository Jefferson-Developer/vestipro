import '../../../../core/utils/utils.dart';
import '../entities/payment_term.dart';

abstract interface class PaymentTermLocalStoreRepository {
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PaymentTerm> paymentTerms,
  });

  Future<AppResult<void>> upsert({required PaymentTerm paymentTerm});

  Future<AppResult<List<PaymentTerm>>> getAll({
    required String organizationId,
    required String companyId,
  });

  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  });
}
