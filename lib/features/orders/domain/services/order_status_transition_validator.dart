import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../value_objects/order_status.dart';

/// Enforces the `Order.status` state machine (EPIC-13, TASK-095, `tasks.md`
/// seção 9.1).
///
/// This is a client-side, domain-level guard only: the Cloud Function behind
/// order submission/status changes must apply the exact same matrix
/// server-side (double validation, same precedent as pricing/RBAC in this
/// codebase) — a client rejecting an invalid transition never substitutes
/// for that server-side check.
///
/// Transitions modeled, following the flow described in TASK-095:
/// - `draft -> pendingSync -> submitted`
/// - `submitted -> underReview -> approved | rejected`
/// - `approved -> processing -> invoiced | partiallyInvoiced`
/// - `partiallyInvoiced -> invoiced` (later fully invoiced) or
///   `partiallyInvoiced -> shipped` (partial shipment ahead of full
///   invoicing, common in fashion B2B pre-booking/backorder flows)
/// - `invoiced -> shipped -> delivered`
/// - `cancelled` is reachable from every status strictly before [shipped]
///   (`draft` through `partiallyInvoiced`, [rejected] included) — once an
///   order has [shipped] or reached [delivered] it can no longer be
///   cancelled outright; undoing it is instead the return/RMA flow below.
/// - `invoiced | partiallyInvoiced | shipped | delivered -> partiallyReturned
///   | returned` (EPIC-30, TASK-199): once at least one `ReturnRequest` for
///   the order is approved, and `partiallyReturned -> returned` once every
///   remaining item is eventually returned too. Applied server-side only, by
///   `resolveReturnRequest` (Admin SDK, bypasses this validator) — never a
///   status a seller/manager picks directly in the UI.
/// - [cancelled] and [returned] are terminal: no further transition is
///   accepted out of them.
@lazySingleton
final class OrderStatusTransitionValidator {
  const OrderStatusTransitionValidator();

  static const Map<OrderStatus, Set<OrderStatus>> _allowedTransitions = {
    OrderStatus.draft: {OrderStatus.pendingSync, OrderStatus.cancelled},
    OrderStatus.pendingSync: {OrderStatus.submitted, OrderStatus.cancelled},
    OrderStatus.submitted: {OrderStatus.underReview, OrderStatus.cancelled},
    OrderStatus.underReview: {
      OrderStatus.approved,
      OrderStatus.rejected,
      OrderStatus.cancelled,
    },
    OrderStatus.approved: {OrderStatus.processing, OrderStatus.cancelled},
    OrderStatus.rejected: {OrderStatus.cancelled},
    OrderStatus.processing: {
      OrderStatus.invoiced,
      OrderStatus.partiallyInvoiced,
      OrderStatus.cancelled,
    },
    OrderStatus.invoiced: {
      OrderStatus.shipped,
      OrderStatus.cancelled,
      OrderStatus.partiallyReturned,
      OrderStatus.returned,
    },
    OrderStatus.partiallyInvoiced: {
      OrderStatus.invoiced,
      OrderStatus.shipped,
      OrderStatus.cancelled,
      OrderStatus.partiallyReturned,
      OrderStatus.returned,
    },
    OrderStatus.shipped: {
      OrderStatus.delivered,
      OrderStatus.partiallyReturned,
      OrderStatus.returned,
    },
    OrderStatus.delivered: {
      OrderStatus.partiallyReturned,
      OrderStatus.returned,
    },
    OrderStatus.cancelled: {},
    OrderStatus.partiallyReturned: {OrderStatus.returned},
    OrderStatus.returned: {},
  };

  /// Whether moving from [from] to [to] is a valid transition. A status
  /// "transitioning" to itself is never valid — callers that have nothing to
  /// change should simply not call this at all.
  bool canTransition(OrderStatus from, OrderStatus to) {
    if (from == to) return false;
    return _allowedTransitions[from]?.contains(to) ?? false;
  }

  /// Throws a [ValidationException] when [from] -> [to] is not a valid
  /// transition; returns normally otherwise.
  void validateTransition({
    required OrderStatus from,
    required OrderStatus to,
  }) {
    if (canTransition(from, to)) return;
    throw ValidationException(
      'Invalid order status transition from "${from.name}" to "${to.name}".',
      code: 'invalid_order_status_transition',
      fieldErrors: <String, String>{
        'status':
            'Transição de "${from.name}" para "${to.name}" não é permitida.',
      },
    );
  }
}
