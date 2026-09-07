import '../../../../core/utils/utils.dart';
import '../entities/order_signature.dart';
import '../entities/order_signature_submission_result.dart';

/// Contract behind submitting a captured `OrderSignature` to the backend
/// (EPIC-13, TASK-180) — every implementation must call `signOrder` (the
/// only Cloud Function allowed to re-verify [OrderSignature.contentHash]
/// against the order's own current server-side state, enforce "never sign
/// twice" and persist the immutable signature record/image), never a
/// client-side write to Firestore/Storage — mirrors
/// `OrderSubmissionRepository`'s own "never a client-side write" contract.
abstract interface class OrderSignatureSubmissionRepository {
  /// Submits [signature] using [signature.id] as the idempotency key/
  /// resulting document id, so a resubmission (retry after a dropped
  /// response, or the offline-capture-then-later-sync flow itself) resolves
  /// to the exact same persisted signature instead of ever creating a
  /// second one for the same pedido.
  Future<AppResult<OrderSignatureSubmissionResult>> submit({
    required OrderSignature signature,
  });
}
