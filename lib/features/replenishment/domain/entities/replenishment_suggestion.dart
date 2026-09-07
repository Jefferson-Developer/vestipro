import '../value_objects/replenishment_suggestion_status.dart';
import 'replenishment_decision_audit_entry.dart';
import 'replenishment_turnover_evidence.dart';

/// A server-computed suggestion to reorder one variant/warehouse
/// (TASK-184, EPIC-27), always presented as a revisable suggestion — never
/// turned into a real order without an explicit human decision
/// (`tasks.md`/TASK-184: "Nenhuma sugestão vira pedido real sem ação humana
/// explícita de aceite").
///
/// One document per `warehouseId`/`variantId`/`periodEnd` combination
/// (`organizations/{organizationId}/replenishmentSuggestions/
/// {warehouseId}_{variantId}_{periodEnd}`), written exclusively by the
/// weekly scheduled `calculateReplenishmentSuggestions` Cloud Function
/// (initial `status`) and by the `decideReplenishmentSuggestion` callable
/// (final `status`/`finalQuantity`/decision fields) — the client never
/// writes this collection directly (`firestore.rules`).
final class ReplenishmentSuggestion {
  const ReplenishmentSuggestion({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.warehouseId,
    required this.variantId,
    required this.productId,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.suggestedQuantity,
    required this.targetStockQuantity,
    required this.currentSellableQuantity,
    required this.futureStockQuantity,
    required this.coverageTargetDays,
    required this.safetyStockQuantity,
    required this.seasonalityFactor,
    required this.decisionAudit,
    required this.generatedAt,
    required this.updatedAt,
    required this.version,
    this.insufficientDataReason,
    this.finalQuantity,
    this.turnoverEvidence,
    this.decidedBy,
    this.decidedByName,
    this.decidedAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String warehouseId;
  final String variantId;
  final String productId;
  final String periodStart;
  final String periodEnd;
  final ReplenishmentSuggestionStatus status;

  /// Reason [status] is `insufficientData` — `null` for every other status.
  final String? insufficientDataReason;

  final int suggestedQuantity;
  final int targetStockQuantity;

  /// `null` until a human decision is made; equals [suggestedQuantity] for
  /// `accepted`, the manually chosen quantity for `adjusted`, and `null`
  /// again (deliberately, never `0`) for `discarded` — a discarded
  /// suggestion was never quantified for reorder at all.
  final int? finalQuantity;

  final int currentSellableQuantity;
  final int futureStockQuantity;

  /// The evidence (giro médio, cobertura, taxa de giro) the suggestion was
  /// computed from — `null` only when there was no turnover history at all
  /// for this variant.
  final ReplenishmentTurnoverEvidence? turnoverEvidence;

  /// The organization's `ReplenishmentParameters` at the moment this
  /// suggestion was generated — frozen forever, independent of any later
  /// change to `replenishmentSettings/default` (`tasks.md`/TASK-184).
  final double coverageTargetDays;
  final double safetyStockQuantity;
  final double seasonalityFactor;

  final String? decidedBy;
  final String? decidedByName;
  final DateTime? decidedAt;
  final List<ReplenishmentDecisionAuditEntry> decisionAudit;

  final DateTime generatedAt;
  final DateTime updatedAt;
  final int version;

  bool get isDecided => status.isDecided;
}
