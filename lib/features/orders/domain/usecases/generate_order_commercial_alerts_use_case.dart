import 'package:injectable/injectable.dart' hide Order;

import '../entities/order.dart';
import 'process_order_commercial_alert_use_case.dart';

/// Orchestrates "pedido com problema" commercial alerts (TASK-153, EPIC-19)
/// for a batch of already-loaded [Order]s, running client-side wherever
/// orders are already loaded for the current viewer (`OrderListBloc`) —
/// mirrors the same client-triggered pattern `GenerateCrmTaskRemindersUseCase`
/// (TASK-152) already established.
@injectable
final class GenerateOrderCommercialAlertsUseCase {
  GenerateOrderCommercialAlertsUseCase(this._processAlert);

  final ProcessOrderCommercialAlertUseCase _processAlert;

  /// Returns how many notifications were actually dispatched (mainly for
  /// tests/telemetry — callers are not expected to react to the count).
  Future<int> call({
    required List<Order> orders,
    required String recipientUserId,
    DateTime? now,
  }) async {
    var dispatched = 0;
    for (final order in orders) {
      final wasDispatched = await _processAlert(
        order: order,
        recipientUserId: recipientUserId,
        now: now,
      );
      if (wasDispatched) dispatched += 1;
    }
    return dispatched;
  }
}
