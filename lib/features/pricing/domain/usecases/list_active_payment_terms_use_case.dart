import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/payment_term.dart';
import '../repositories/payment_term_repository.dart';

@injectable
final class ListActivePaymentTermsUseCase {
  const ListActivePaymentTermsUseCase(this._repository);

  final PaymentTermRepository _repository;

  Future<AppResult<List<PaymentTerm>>> call({
    required String organizationId,
    required String companyId,
    String? priceListId,
  }) async {
    final result = await _repository.listByCompany(
      organizationId: organizationId.trim(),
      companyId: companyId.trim(),
    );
    return result.fold(
      onSuccess: (terms) {
        final filtered =
            terms
                .where((term) => term.isActive)
                .where((term) => term.isCompatibleWithPriceList(priceListId))
                .toList(growable: false)
              ..sort((a, b) => a.name.compareTo(b.name));
        return AppSuccess<List<PaymentTerm>>(filtered);
      },
      onFailure: AppFailure<List<PaymentTerm>>.new,
    );
  }
}
