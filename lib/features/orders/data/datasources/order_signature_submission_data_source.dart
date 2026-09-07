import '../../domain/entities/order_signature.dart';
import '../dtos/order_signature_submission_result_dto.dart';

/// Contract behind the raw remote call submitting a captured
/// `OrderSignature` (EPIC-13, TASK-180) — mirrors
/// `OrderSubmissionDataSource`'s own shape for `Order` itself.
abstract interface class OrderSignatureSubmissionDataSource {
  Future<OrderSignatureSubmissionResultDto> submit({
    required OrderSignature signature,
  });
}
