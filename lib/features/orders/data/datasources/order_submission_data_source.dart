import '../../domain/entities/order.dart';
import '../dtos/order_submission_result_dto.dart';

/// Remote submission of an `Order` draft (EPIC-13, TASK-101) — the contract
/// [OrderSubmissionRepositoryImpl] talks to; the only real implementation
/// calls `submitOrder`, never writes an order to Firestore directly (that
/// would defeat the whole point of a server-side idempotent/authoritative
/// submission).
abstract interface class OrderSubmissionDataSource {
  Future<OrderSubmissionResultDto> submit({
    required Order order,
    required String idempotencyKey,
  });
}
