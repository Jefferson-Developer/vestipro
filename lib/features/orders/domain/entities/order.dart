import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/order_status.dart';
import '../value_objects/order_sync_status.dart';
import 'order_address.dart';
import 'order_item.dart';
import 'order_status_history_entry.dart';

part 'order.freezed.dart';

/// Order / pedido aggregate (EPIC-13, TASK-095, `tasks.md` seção 9).
///
/// This is the base structural model for the whole EPIC-13: no submission,
/// pricing, approval or total-calculation rule is implemented here (those
/// belong to later EPIC-13 tasks) — only the fields and the status state
/// machine every one of those tasks builds on top of.
///
/// The tenant fields [organizationId] and [companyId] are immutable after
/// creation and must be resolved from the authenticated session/active
/// organization context, never from a form field — same contract every other
/// tenant-scoped entity in this codebase (`Customer`, `PriceList`) already
/// follows. [organizationId]/[companyId] are never trusted from the client
/// as authorization either way: the Cloud Function that ultimately accepts a
/// submitted order must re-validate both server-side.
///
/// [status] transitions must only ever be produced by
/// `OrderStatusTransitionValidator` — never assigned ad hoc from UI or
/// repository code — and every accepted transition must append one entry to
/// [statusHistory].
@freezed
abstract class Order with _$Order {
  const Order._();

  const factory Order({
    required String id,
    required String organizationId,
    required String companyId,
    required String branchId,
    required String customerId,
    required String sellerId,
    // The definitive, sequential order number `submitOrder` (TASK-101)
    // generates server-side — `null` until this `Order` has actually been
    // submitted (a `draft`/`pendingSync` order never has one). Read-only from
    // the client's perspective: nothing in this codebase other than
    // `_submitOrder` (`app/bootstrap.dart`), reconciling a successful
    // `OrderSubmissionResult`, may ever set it.
    String? orderNumber,
    required OrderAddress deliveryAddress,
    required OrderAddress billingAddress,
    required String priceListId,
    required String paymentTermId,
    String? carrierId,
    // "coleção" — the product collection this order was placed against, if
    // the seller narrowed the catalog to one (TASK-072 area).
    String? collectionId,
    // "tipo de pedido" — free-form categorization code (e.g. normal, sample,
    // bonus/gift), intentionally not a closed enum: `tasks.md` seção 9 does
    // not fix its possible values, same precedent as `Customer.classification`.
    String? orderType,
    @Default(<OrderItem>[]) List<OrderItem> items,
    @Default(0) double discountAmount,
    @Default(0) double surchargeAmount,
    @Default(0) double shippingAmount,
    double? taxAmount,
    String? notes,
    @Default(<String>[]) List<String> attachmentUrls,
    required OrderStatus status,
    @Default(<OrderStatusHistoryEntry>[])
    List<OrderStatusHistoryEntry> statusHistory,
    // Approval metadata: only ever set by the (future) approval flow, never
    // inferred from [status] alone.
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    required int version,
    required OrderSyncStatus syncStatus,
  }) = _Order;

  /// Sum of every item's captured [OrderItem.subtotal] — the items-only
  /// subtotal, before order-level [discountAmount]/[surchargeAmount]/
  /// [shippingAmount]/[taxAmount]. The definitive order total is a
  /// server-side pricing/submission concern (later EPIC-13 task), not
  /// implemented here.
  double get itemsSubtotal {
    return items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  int get itemCount => items.length;
}
