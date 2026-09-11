import '../value_objects/backorder_origin.dart';
import '../value_objects/backorder_priority.dart';
import '../value_objects/backorder_status.dart';

/// A registered demand for a produto/variante sem estoque pronta entrega
/// suficiente (TASK-215, EPIC-32) — never, by itself, moves/reserves a
/// single unit of stock nor promises a delivery date
/// (`tasks.md`: "Backorder não reduz saldo de estoque atual nem garante
/// entrega sem confirmação posterior"). Exclusively written by the
/// `createBackorderRequest`/`decideBackorderApproval`/
/// `cancelBackorderRequest`/`convertBackorderToOrder`/
/// `notifyBackordersOnStockAvailable` Cloud Functions (`AGENTS.md`: UI nunca
/// acessa Firestore diretamente) — the UI only ever reads this entity back
/// through `BackorderRepository.watchQueue`/`watchAwaitingApproval`/
/// `watchForCustomer`.
final class BackorderRequest {
  const BackorderRequest({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.productId,
    required this.variantId,
    this.sku,
    required this.quantity,
    required this.fulfilledQuantity,
    required this.quantityAtRequest,
    required this.origin,
    required this.priority,
    required this.sellerId,
    this.relatedOrderId,
    this.relatedOrderItemId,
    this.requestedDeliveryDate,
    this.estimatedUnitPrice,
    this.notes,
    required this.status,
    this.resolutionNote,
    this.convertedOrderId,
    this.convertedAt,
    this.expectedAvailabilityDate,
    required this.requestedBy,
    this.requestedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String customerId;
  final String productId;
  final String variantId;
  final String? sku;

  /// Original quantity requested — never changed after creation.
  final int quantity;

  /// Quantity already covered by a conversion (`convertBackorderToOrder`) —
  /// `0` until [status] reaches [BackorderStatus.converted].
  final int fulfilledQuantity;

  /// Total sellable quantity across every warehouse snapshotted at the exact
  /// moment this request was created — informational only ("estoque no
  /// momento da solicitação"), never revalidated after the fact.
  final int quantityAtRequest;

  final BackorderOrigin origin;
  final BackorderPriority priority;

  /// The vendedor responsável — whoever `createBackorderRequest` resolved
  /// this to (the requester itself for `SALES_REP`, an explicit seller for a
  /// gestor, or the linked pedido's own seller).
  final String sellerId;

  final String? relatedOrderId;
  final String? relatedOrderItemId;
  final DateTime? requestedDeliveryDate;

  /// Display-only estimate captured at request time (e.g. the catalog's own
  /// current price) — never a binding quote; the price actually charged is
  /// always whatever the linked pedido's own submission revalidated.
  final double? estimatedUnitPrice;

  final String? notes;
  final BackorderStatus status;

  /// Free-text note attached to a rejection/cancellation decision.
  final String? resolutionNote;

  final String? convertedOrderId;
  final DateTime? convertedAt;

  /// Set once `notifyBackordersOnStockAvailable` flags this request
  /// [BackorderStatus.readyToFulfill] — a heads-up, never a confirmed
  /// delivery date.
  final DateTime? expectedAvailabilityDate;

  final String requestedBy;
  final String? requestedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Quantity still pending atendimento — `0` once fully converted.
  int get remainingQuantity => quantity - fulfilledQuantity;

  bool get isOpen => status.isOpen;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackorderRequest &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.companyId == companyId &&
          other.customerId == customerId &&
          other.productId == productId &&
          other.variantId == variantId &&
          other.sku == sku &&
          other.quantity == quantity &&
          other.fulfilledQuantity == fulfilledQuantity &&
          other.quantityAtRequest == quantityAtRequest &&
          other.origin == origin &&
          other.priority == priority &&
          other.sellerId == sellerId &&
          other.relatedOrderId == relatedOrderId &&
          other.relatedOrderItemId == relatedOrderItemId &&
          other.requestedDeliveryDate == requestedDeliveryDate &&
          other.estimatedUnitPrice == estimatedUnitPrice &&
          other.notes == notes &&
          other.status == status &&
          other.resolutionNote == resolutionNote &&
          other.convertedOrderId == convertedOrderId &&
          other.convertedAt == convertedAt &&
          other.expectedAvailabilityDate == expectedAvailabilityDate &&
          other.requestedBy == requestedBy &&
          other.requestedByName == requestedByName &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    organizationId,
    companyId,
    customerId,
    productId,
    variantId,
    sku,
    quantity,
    fulfilledQuantity,
    quantityAtRequest,
    origin,
    priority,
    sellerId,
    relatedOrderId,
    relatedOrderItemId,
    requestedDeliveryDate,
    estimatedUnitPrice,
    notes,
    status,
    resolutionNote,
    convertedOrderId,
    convertedAt,
    expectedAvailabilityDate,
    requestedBy,
    requestedByName,
    createdAt,
    updatedAt,
  ]);
}
