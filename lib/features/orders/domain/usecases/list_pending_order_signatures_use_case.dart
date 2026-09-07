import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/order_signature.dart';
import '../repositories/order_signature_draft_repository.dart';

/// Lists every `OrderSignature` still pending sync on this device (EPIC-13,
/// TASK-180) — mirrors `ListLocalPendingOrdersUseCase`'s own shape. The
/// resulting list is what a future retry entry point (Central de
/// Sincronização/app-resume hook — see the CONCLUIDA doc's own
/// "Pendências", not wired into the UI by this task) would resubmit through
/// `SubmitOrderSignatureUseCase` one by one.
@injectable
class ListPendingOrderSignaturesUseCase {
  const ListPendingOrderSignaturesUseCase(this._repository);

  final OrderSignatureDraftRepository _repository;

  Future<AppResult<List<OrderSignature>>> call({
    required String organizationId,
    required String companyId,
  }) {
    return _repository.getPendingSync(
      organizationId: organizationId,
      companyId: companyId,
    );
  }
}
