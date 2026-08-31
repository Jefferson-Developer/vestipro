import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_submission_result.dart';
import '../repositories/order_submission_repository.dart';

/// Submits an `Order` draft for real (EPIC-13, TASK-101), through the
/// idempotent `submitOrder` Cloud Function — the one and only place a
/// pedido's final `orderNumber`, price/estoque revalidation and `submitted`
/// status transition are decided; nothing here recomputes any of that.
///
/// [Order.id] is reused verbatim as the submission's own idempotency key:
/// it is already a uuid minted once when the draft was first created
/// (`OrderDraftCustomerSelected`, TASK-096) and never regenerated afterwards,
/// so resubmitting the very same draft (double tap on "Enviar pedido",
/// retry after a dropped response) always carries the same key — exactly
/// the guarantee `submitOrder` needs to never create two orders for one
/// seller intent.
@injectable
final class SubmitOrderUseCase {
  const SubmitOrderUseCase(this._repository, this._analyticsService);

  final OrderSubmissionRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<OrderSubmissionResult>> call({required Order order}) async {
    if (order.items.isEmpty) {
      return const AppFailure<OrderSubmissionResult>(
        ValidationFailure(
          'Order has no items to submit.',
          code: 'order_submission_no_items',
        ),
      );
    }

    final result = await _repository.submit(
      order: order,
      idempotencyKey: order.id,
    );
    if (result case AppSuccess<OrderSubmissionResult>(
      value: final submission,
    )) {
      await _analyticsService.logEvent(
        AnalyticsEvents.orderSubmitted,
        parameters: <String, Object?>{
          'organization_id': order.organizationId,
          'company_id': order.companyId,
          'order_id': submission.orderId,
          'order_number': submission.orderNumber,
          'status': submission.status.name,
          'total': submission.total,
          'item_count': order.itemCount,
        },
      );
    }
    return result;
  }
}
