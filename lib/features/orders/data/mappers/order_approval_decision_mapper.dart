import 'package:injectable/injectable.dart' hide Order;

import '../../domain/entities/order_approval_decision_result.dart';
import '../dtos/order_approval_decision_result_dto.dart';
import 'order_mapper.dart';

/// Translates `decideOrderApproval`'s plain-JSON response DTO
/// ([OrderApprovalDecisionResultDto]) into the domain's
/// [OrderApprovalDecisionResult] — every field is copied as-is, never
/// recomputed, reusing [OrderMapper.statusToEntity] for the `status` code so
/// no second place decides what a given wire status string means (same
/// precedent `OrderSubmissionMapper` already sets).
@injectable
final class OrderApprovalDecisionMapper {
  const OrderApprovalDecisionMapper(this._orderMapper);

  final OrderMapper _orderMapper;

  OrderApprovalDecisionResult toEntity(OrderApprovalDecisionResultDto dto) {
    return OrderApprovalDecisionResult(
      orderId: dto.orderId,
      status: _orderMapper.statusToEntity(dto.status),
      approverId: dto.approverId,
      decidedAt: dto.decidedAt,
      reason: dto.reason,
    );
  }
}
