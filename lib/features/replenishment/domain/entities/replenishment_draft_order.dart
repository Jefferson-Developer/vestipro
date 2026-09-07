import 'replenishment_draft_order_item.dart';

/// A minimal, internal-only draft created when a gestor accepts/adjusts one
/// or more `ReplenishmentSuggestion`s (TASK-184, EPIC-27) —
/// `organizations/{organizationId}/replenishmentDraftOrders/{id}`.
///
/// Deliberately **not** a reuse of `Order`/`OrderItem` (EPIC-13, TASK-096):
/// a real customer `Order` requires `customerId`/`deliveryAddress`/
/// `billingAddress`/`priceListId`/`paymentTermId`
/// (`lib/features/orders/domain/entities/order.dart`), none of which exist
/// for an internal warehouse/factory reposição — there is no customer, no
/// delivery/billing address and no price list involved. See TASK-184's own
/// `docs/tasks/TASK-184-...-CONCLUIDA.md`, "Decisões técnicas", for the full
/// rationale.
///
/// Written exclusively by `decideReplenishmentSuggestion` (Cloud Function,
/// `action: 'accept'` or `'adjust'`) — never client-writable
/// (`firestore.rules`). This app only ever reads it (e.g. to show "esta
/// sugestão já gerou o rascunho X"); turning a
/// [ReplenishmentDraftOrder] into a real purchase order/transferência is out
/// of TASK-184's scope.
final class ReplenishmentDraftOrder {
  const ReplenishmentDraftOrder({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.warehouseId,
    required this.items,
    required this.sourceSuggestionIds,
    required this.originType,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String warehouseId;
  final List<ReplenishmentDraftOrderItem> items;
  final List<String> sourceSuggestionIds;

  /// Always `'replenishment'` today — kept as a string (not an enum with a
  /// single value) so a future non-replenishment draft-order origin could
  /// reuse this same aggregate without a breaking migration.
  final String originType;

  /// Always `'draft'` today — TASK-184 stops at generating the draft; a
  /// future task decides what "confirming"/"sending" one actually means.
  final String status;

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;
}
