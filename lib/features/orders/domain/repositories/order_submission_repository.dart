import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_submission_result.dart';

/// Contract behind submitting an `Order` draft (EPIC-13, TASK-101) — every
/// implementation must call `submitOrder` (the only Cloud Function allowed
/// to generate the final `orderNumber`, revalidate TASK-100's conditions and
/// persist the `submitted` transition), never a client-side write to
/// Firestore.
abstract interface class OrderSubmissionRepository {
  /// Submits [order] using [idempotencyKey] to make a resubmission (double
  /// tap, retry after a dropped response) resolve to the exact same result
  /// instead of creating a duplicate order.
  Future<AppResult<OrderSubmissionResult>> submit({
    required Order order,
    required String idempotencyKey,
  });
}
