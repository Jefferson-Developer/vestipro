import '../../../../core/utils/utils.dart';
import '../entities/backorder_request.dart';
import '../value_objects/backorder_origin.dart';
import '../value_objects/backorder_priority.dart';

abstract interface class BackorderRepository {
  /// Every `BackorderRequest` eligible for the priorized atendimento queue
  /// (`BackorderStatus.isQueueable` — `queued`/`ready_to_fulfill`), ordered
  /// by priority (highest first) then age (oldest first) — TASK-215: "fila
  /// de atendimento de backorder, priorizada por cliente, data, valor
  /// potencial, segmento ou política comercial".
  Stream<AppResult<List<BackorderRequest>>> watchQueue({
    required String organizationId,
  });

  /// Every `BackorderRequest` parked at `awaiting_approval` — the inbox a
  /// gestor (`Capability.backorderApprove`) works through via
  /// `decideBackorderApproval`, oldest first.
  Stream<AppResult<List<BackorderRequest>>> watchAwaitingApproval({
    required String organizationId,
  });

  /// Every `BackorderRequest` ever opened for [customerId], newest first —
  /// feeds the cliente 360º/histórico view.
  Stream<AppResult<List<BackorderRequest>>> watchForCustomer({
    required String organizationId,
    required String customerId,
  });

  /// Calls `createBackorderRequest` (Cloud Function) — never a direct
  /// Firestore write. [backorderId] is the client-generated idempotency
  /// key/document id, same precedent `shipmentId`/`returnRequestId` already
  /// set.
  Future<AppResult<void>> createBackorderRequest({
    required String organizationId,
    required String companyId,
    required String backorderId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required BackorderOrigin origin,
    BackorderPriority priority = BackorderPriority.normal,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    DateTime? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  });

  /// Calls `decideBackorderApproval` (Cloud Function) — the only place a
  /// backorder parked at `awaiting_approval` ever advances to `queued`/
  /// `rejected`.
  Future<AppResult<void>> decideBackorderApproval({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  });

  /// Calls `cancelBackorderRequest` (Cloud Function) — only ever accepted
  /// while [BackorderRequest.isOpen].
  Future<AppResult<void>> cancelBackorderRequest({
    required String organizationId,
    required String backorderId,
    String? reason,
  });

  /// Calls `convertBackorderToOrder` (Cloud Function), linking an
  /// already-submitted [orderId] (created through the existing pedido em
  /// rascunho → submissão flow, itself already revalidating preço/estoque/
  /// crédito/aprovação) to a `queued`/`ready_to_fulfill` backorder.
  Future<AppResult<void>> convertBackorderToOrder({
    required String organizationId,
    required String backorderId,
    required String orderId,
  });
}
