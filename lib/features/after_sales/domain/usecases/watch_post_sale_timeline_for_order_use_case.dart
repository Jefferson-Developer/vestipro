import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/post_sale_event.dart';
import '../repositories/post_sale_event_repository.dart';

/// Streams every `PostSaleEvent` linked to one pedido (TASK-201/TASK-102) —
/// feeds the pós-venda timeline embedded in the order detail screen,
/// including the devolução/troca events auto-appended by TASK-199/TASK-200's
/// own Cloud Functions.
@injectable
final class WatchPostSaleTimelineForOrderUseCase {
  const WatchPostSaleTimelineForOrderUseCase(this._repository);

  final PostSaleEventRepository _repository;

  Stream<AppResult<List<PostSaleEvent>>> call({
    required String organizationId,
    required String orderId,
  }) {
    return _repository.watchByOrder(
      organizationId: organizationId,
      orderId: orderId,
    );
  }
}
