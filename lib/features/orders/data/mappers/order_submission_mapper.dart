// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent `OrderMapper`
// already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../domain/entities/order_submission_result.dart';
import '../dtos/order_submission_result_dto.dart';
import 'order_mapper.dart';

/// Translates `submitOrder`'s plain-JSON response DTO
/// ([OrderSubmissionResultDto]) into the domain's [OrderSubmissionResult] —
/// every numeric/status field is copied as-is, never recomputed, same
/// "nunca um cálculo divergente feito apenas na interface" rule
/// `OrderPricingMapper` already follows. Reuses [OrderMapper.statusToEntity]
/// for the `status` code so no second place decides what a given wire status
/// string means.
@injectable
final class OrderSubmissionMapper {
  const OrderSubmissionMapper(this._orderMapper);

  final OrderMapper _orderMapper;

  OrderSubmissionResult toEntity(OrderSubmissionResultDto dto) {
    return OrderSubmissionResult(
      orderId: dto.orderId,
      orderNumber: dto.orderNumber,
      status: _orderMapper.statusToEntity(dto.status),
      discountAmount: dto.discountAmount,
      surchargeAmount: dto.surchargeAmount,
      shippingAmount: dto.shippingAmount,
      total: dto.total,
      submittedAt: dto.submittedAt,
    );
  }
}
