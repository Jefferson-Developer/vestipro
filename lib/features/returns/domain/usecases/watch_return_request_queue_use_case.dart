import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../orders/domain/entities/order_visibility_filter.dart';
import '../../../orders/domain/services/order_visibility_service.dart';
import '../entities/return_request.dart';
import '../repositories/return_request_repository.dart';

/// Streams every devolução still solicitada that the caller may decide
/// (TASK-199, EPIC-30) — reuses [OrderVisibilityService] (TASK-102) instead
/// of re-deriving the OWNER/ADMIN/SALES_MANAGER/SALES_REP visibility
/// branching a second time: a devolução is only ever visible to whoever
/// could already see the pedido it is attached to (same scope
/// `canReadReturnRequest`, `firestore.rules`, independently re-verifies).
@injectable
final class WatchReturnRequestQueueUseCase {
  const WatchReturnRequestQueueUseCase(
    this._repository,
    this._visibilityService,
  );

  final ReturnRequestRepository _repository;
  final OrderVisibilityService _visibilityService;

  Stream<AppResult<List<ReturnRequest>>> call({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async* {
    final visibilityResult = await _visibilityService.resolve(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
    );
    if (visibilityResult case AppFailure<OrderVisibilityFilter>(
      failure: final failure,
    )) {
      yield AppFailure<List<ReturnRequest>>(failure);
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<OrderVisibilityFilter>).value;
    if (!visibility.canReadAny) {
      yield const AppSuccess<List<ReturnRequest>>(<ReturnRequest>[]);
      return;
    }

    yield* _repository.watchQueue(
      organizationId: organizationId,
      companyId: companyId,
      allCompany: visibility.mode == OrderVisibilityMode.allCompany,
      sellerIds: visibility.sellerIds,
    );
  }
}
