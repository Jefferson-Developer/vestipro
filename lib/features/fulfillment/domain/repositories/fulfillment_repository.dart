import '../../../../core/utils/utils.dart';
import '../entities/logistics_issue.dart';
import '../entities/shipment.dart';
import '../entities/tracking_event.dart';
import '../value_objects/logistics_issue_type.dart';

abstract interface class FulfillmentRepository {
  /// Every `Shipment` opened against [orderId] — feeds the pedido's own
  /// rastreio section (TASK-214/TASK-102). More than one may exist for the
  /// same pedido (entregas parciais expedidas separadamente).
  Stream<AppResult<List<Shipment>>> watchShipmentsForOrder({
    required String organizationId,
    required String orderId,
  });

  /// The full, append-only tracking history of [shipmentId], ordered from
  /// oldest to newest.
  Stream<AppResult<List<TrackingEvent>>> watchTrackingEvents({
    required String organizationId,
    required String shipmentId,
  });

  /// Every `LogisticsIssue`/ocorrência ever opened against [shipmentId],
  /// newest first.
  Stream<AppResult<List<LogisticsIssue>>> watchLogisticsIssues({
    required String organizationId,
    required String shipmentId,
  });

  /// Calls `registerLogisticsIssue` (Cloud Function) — never a direct
  /// Firestore write. [logisticsIssueId] is the client-generated idempotency
  /// key/document id, same precedent `returnRequestId` already sets.
  Future<AppResult<void>> registerLogisticsIssue({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required LogisticsIssueType type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  });

  /// Calls `resolveLogisticsIssue` (Cloud Function) — the only place a
  /// `LogisticsIssue` ever advances to `in_progress`/`resolved`, clearing
  /// `Shipment.hasOpenIssue` once no other open ocorrência remains.
  Future<AppResult<void>> resolveLogisticsIssue({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required bool resolved,
    String? resolutionNote,
  });
}
