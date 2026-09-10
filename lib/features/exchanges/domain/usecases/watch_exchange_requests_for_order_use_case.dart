import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/exchange_request.dart';
import '../repositories/exchange_request_repository.dart';

/// Streams every troca linked to one pedido (TASK-200/TASK-102) — feeds the
/// history section embedded in the order detail screen.
@injectable
final class WatchExchangeRequestsForOrderUseCase {
  const WatchExchangeRequestsForOrderUseCase(this._repository);

  final ExchangeRequestRepository _repository;

  Stream<AppResult<List<ExchangeRequest>>> call({
    required String organizationId,
    required String orderId,
  }) {
    return _repository.watchByOrder(
      organizationId: organizationId,
      orderId: orderId,
    );
  }
}
