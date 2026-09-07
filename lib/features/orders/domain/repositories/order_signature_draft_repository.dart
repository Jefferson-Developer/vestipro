import '../../../../core/utils/utils.dart';
import '../entities/order_signature.dart';

/// Domain contract for the fully offline persistence of an `OrderSignature`
/// (EPIC-13, TASK-180) — mirrors `OrderDraftRepository`'s own "100% local,
/// never a network call" contract: submitting a captured signature to the
/// backend (`signOrder`) is [OrderSignatureSubmissionRepository]'s separate
/// concern, exactly like `Order` itself splits `OrderDraftRepository` from
/// `OrderSubmissionRepository`.
abstract interface class OrderSignatureDraftRepository {
  /// Persists [signature] locally — insert on first capture, full replace on
  /// every subsequent reconciliation (e.g. marking it [OrderSignatureSyncStatus
  /// .synced] once `signOrder` confirms it). Never contacts the network.
  Future<AppResult<void>> saveLocal({required OrderSignature signature});

  /// The signature captured for [orderId] on this device, scoped to
  /// [organizationId]/[companyId], or `null` when this order has never been
  /// signed from this device. Never contacts the network — a signature
  /// captured on a *different* device is out of this task's scope (see the
  /// CONCLUIDA doc's own "Pendências").
  Future<AppResult<OrderSignature?>> getByOrderId({
    required String organizationId,
    required String companyId,
    required String orderId,
  });

  /// Every locally captured `OrderSignature` still pending sync
  /// (`OrderSignatureSyncStatus.pendingSync`/`.failed`) for
  /// [organizationId]/[companyId] — the retry-sync entry point
  /// (`RetryPendingOrderSignaturesUseCase`) reads this the same way
  /// `ListLocalPendingOrdersUseCase` reads pending orders.
  Future<AppResult<List<OrderSignature>>> getPendingSync({
    required String organizationId,
    required String companyId,
  });
}
