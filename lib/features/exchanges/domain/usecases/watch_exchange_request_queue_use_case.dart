import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../orders/domain/entities/order_visibility_filter.dart';
import '../../../orders/domain/services/order_visibility_service.dart';
import '../entities/exchange_request.dart';
import '../repositories/exchange_request_repository.dart';

/// Streams every troca still solicitada that the caller may decide
/// (TASK-200, EPIC-30) — reuses [OrderVisibilityService] (TASK-102) instead
/// of re-deriving the OWNER/ADMIN/SALES_MANAGER/SALES_REP visibility
/// branching a second time, same precedent `WatchReturnRequestQueueUseCase`
/// (TASK-199) already sets: a troca is only ever visible to whoever could
/// already see the pedido it is attached to (same scope
/// `canReadExchangeRequest`, `firestore.rules`, independently re-verifies).
@injectable
final class WatchExchangeRequestQueueUseCase {
  const WatchExchangeRequestQueueUseCase(
    this._repository,
    this._visibilityService,
  );

  final ExchangeRequestRepository _repository;
  final OrderVisibilityService _visibilityService;

  Stream<AppResult<List<ExchangeRequest>>> call({
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
      yield AppFailure<List<ExchangeRequest>>(failure);
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<OrderVisibilityFilter>).value;
    if (!visibility.canReadAny) {
      yield const AppSuccess<List<ExchangeRequest>>(<ExchangeRequest>[]);
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
