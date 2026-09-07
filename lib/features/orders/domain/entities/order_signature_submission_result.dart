import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_signature_submission_result.freezed.dart';

/// The `signOrder` Cloud Function's own confirmed result (EPIC-13,
/// TASK-180) — every field here is server-authoritative and reconciled back
/// onto the local `OrderSignature` record by `SubmitOrderSignatureUseCase`,
/// mirroring exactly how `OrderSubmissionResult` is reconciled onto the
/// local `Order` after `submitOrder`.
@freezed
abstract class OrderSignatureSubmissionResult
    with _$OrderSignatureSubmissionResult {
  const factory OrderSignatureSubmissionResult({
    required String signatureId,
    required String remoteImageStoragePath,
    required DateTime serverReceivedAt,
    // Resolved server-side from the callable's own `_meta` (app
    // version/platform) — advisory metadata, never used for authorization,
    // same status every other Function already treats `_meta` with.
    String? deviceInfo,
    // Resolved server-side from the request's own IP — never trusted from
    // (or even sent by) the client, unlike every other field this callable
    // receives.
    String? ipAddress,
  }) = _OrderSignatureSubmissionResult;
}
