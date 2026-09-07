import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/order_signature.dart';
import '../repositories/order_signature_draft_repository.dart';

/// The `OrderSignature` captured for one order on this device, or `null`
/// when none exists yet (EPIC-13, TASK-180) — the read side
/// `OrderHistoryPage`/the comprovante PDF use to decide whether to offer
/// "Assinar pedido" or render the already-captured evidence instead. Purely
/// local (mirrors `GetOrderDraftUseCase`'s own "never a network call" shape)
/// — see `OrderSignatureDraftRepository.getByOrderId`'s own docs for why a
/// signature captured on a different device is out of this task's scope.
@injectable
class GetOrderSignatureUseCase {
  const GetOrderSignatureUseCase(this._repository);

  final OrderSignatureDraftRepository _repository;

  Future<AppResult<OrderSignature?>> call({
    required String organizationId,
    required String companyId,
    required String orderId,
  }) {
    return _repository.getByOrderId(
      organizationId: organizationId,
      companyId: companyId,
      orderId: orderId,
    );
  }
}
