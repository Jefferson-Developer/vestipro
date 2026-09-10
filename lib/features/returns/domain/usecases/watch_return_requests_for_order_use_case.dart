import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/return_request.dart';
import '../repositories/return_request_repository.dart';

/// Streams every devolução linked to one pedido (TASK-199/TASK-102) — feeds
/// the history section embedded in the order detail screen.
@injectable
final class WatchReturnRequestsForOrderUseCase {
  const WatchReturnRequestsForOrderUseCase(this._repository);

  final ReturnRequestRepository _repository;

  Stream<AppResult<List<ReturnRequest>>> call({
    required String organizationId,
    required String orderId,
  }) {
    return _repository.watchByOrder(
      organizationId: organizationId,
      orderId: orderId,
    );
  }
}
