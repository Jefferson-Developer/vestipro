import '../../../../core/utils/utils.dart';
import '../entities/payment_term.dart';

abstract interface class PaymentTermRepository {
  Future<AppResult<PaymentTerm>> create({required PaymentTerm paymentTerm});

  Future<AppResult<PaymentTerm>> update({required PaymentTerm paymentTerm});

  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  });
}
