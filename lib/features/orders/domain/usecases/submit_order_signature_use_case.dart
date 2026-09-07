import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order_signature.dart';
import '../entities/order_signature_submission_result.dart';
import '../repositories/order_signature_draft_repository.dart';
import '../repositories/order_signature_submission_repository.dart';
import '../value_objects/order_signature_sync_status.dart';

/// Submits an already-captured `OrderSignature` to the backend (EPIC-13,
/// TASK-180), through the idempotent `signOrder` Cloud Function — the one
/// and only place [OrderSignature.contentHash] is re-verified against the
/// order's own current server-side state and the signature's own
/// server-side metadata ([OrderSignature.serverReceivedAt]/[deviceInfo]/
/// [ipAddress]) is decided.
///
/// [OrderSignature.id] is reused verbatim as this submission's own
/// idempotency key — minted once at capture time
/// (`CaptureOrderSignatureUseCase`) and never regenerated afterwards, so
/// resubmitting the very same capture (retry after the app was closed
/// offline, connectivity flapping) always carries the same key. On success,
/// the local record is reconciled to [OrderSignatureSyncStatus.synced] with
/// the server's own confirmed metadata — mirroring exactly how
/// `submitOrderFromDraft` reconciles a submitted `Order`'s local copy.
@injectable
class SubmitOrderSignatureUseCase {
  const SubmitOrderSignatureUseCase(
    this._submissionRepository,
    this._draftRepository,
    this._analyticsService,
  );

  final OrderSignatureSubmissionRepository _submissionRepository;
  final OrderSignatureDraftRepository _draftRepository;
  final AnalyticsService _analyticsService;

  Future<AppResult<OrderSignature>> call({
    required OrderSignature signature,
  }) async {
    final result = await _submissionRepository.submit(signature: signature);
    if (result case AppFailure<OrderSignatureSubmissionResult>(
      failure: final failure,
    )) {
      await _analyticsService.logEvent(
        AnalyticsEvents.orderSignatureSyncFailed,
        parameters: <String, Object?>{
          'organization_id': signature.organizationId,
          'company_id': signature.companyId,
          'order_id': signature.orderId,
        },
      );
      return AppFailure<OrderSignature>(failure);
    }

    final confirmation =
        (result as AppSuccess<OrderSignatureSubmissionResult>).value;
    final synced = signature.copyWith(
      remoteImageStoragePath: confirmation.remoteImageStoragePath,
      serverReceivedAt: confirmation.serverReceivedAt,
      deviceInfo: confirmation.deviceInfo,
      ipAddress: confirmation.ipAddress,
      syncStatus: OrderSignatureSyncStatus.synced,
      updatedAt: confirmation.serverReceivedAt,
    );

    final saveResult = await _draftRepository.saveLocal(signature: synced);
    if (saveResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<OrderSignature>(failure);
    }

    await _analyticsService.logEvent(
      AnalyticsEvents.orderSignatureSynced,
      parameters: <String, Object?>{
        'organization_id': synced.organizationId,
        'company_id': synced.companyId,
        'order_id': synced.orderId,
        'signer_role': synced.signerRole.name,
      },
    );
    return AppSuccess<OrderSignature>(synced);
  }
}
