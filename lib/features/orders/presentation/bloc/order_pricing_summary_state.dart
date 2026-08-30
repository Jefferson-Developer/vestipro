import '../../../../core/errors/errors.dart';
import '../../domain/entities/order_pricing_summary.dart';

/// Lifecycle of the order draft's commercial summary card (EPIC-13,
/// TASK-099).
enum OrderPricingSummaryStatus {
  /// Nothing to price yet (draft has no items) — the card stays hidden.
  initial,

  /// Waiting for `calculatePricing`'s response — never blocks the rest of
  /// the draft screen (item edits keep working while this is in flight).
  recalculating,

  /// [OrderPricingSummaryState.summary] is exactly what the pricing engine
  /// returned for the items currently on the draft.
  success,

  /// `calculatePricing` could not be reached (offline/connectivity failure)
  /// — [OrderPricingSummaryState.localEstimateSubtotal]/
  /// [OrderPricingSummaryState.localEstimateShippingAmount] hold a purely
  /// local, discount-less estimate, and the UI must make clear it is not yet
  /// confirmed by the pricing engine (`tasks.md`/TASK-099).
  offlineEstimate,

  /// A real error other than connectivity (validation, server, permission)
  /// — never silent, always surfaced through
  /// [OrderPricingSummaryState.failure].
  failure,
}

/// State of `OrderPricingSummaryCubit` (EPIC-13, TASK-099).
final class OrderPricingSummaryState {
  const OrderPricingSummaryState({
    this.status = OrderPricingSummaryStatus.initial,
    this.summary,
    this.localEstimateSubtotal,
    this.localEstimateShippingAmount,
    this.failure,
  });

  final OrderPricingSummaryStatus status;

  /// The pricing engine's own result — the only authoritative source for
  /// subtotal/desconto/acréscimo/frete/total once [status] is
  /// [OrderPricingSummaryStatus.success].
  final OrderPricingSummary? summary;

  /// Local, discount-less fallback (`Order.itemsSubtotal` +
  /// `Order.shippingAmount`) shown only while [status] is
  /// [OrderPricingSummaryStatus.offlineEstimate] — deliberately never a
  /// substitute for [summary]: it carries no desconto/acréscimo, since those
  /// require the server-side engine this state could not reach.
  final double? localEstimateSubtotal;
  final double? localEstimateShippingAmount;
  final Failure? failure;

  bool get isRecalculating => status == OrderPricingSummaryStatus.recalculating;

  bool get isOfflineEstimate =>
      status == OrderPricingSummaryStatus.offlineEstimate;

  bool get hasFailure => status == OrderPricingSummaryStatus.failure;

  double? get localEstimateTotal {
    final subtotal = localEstimateSubtotal;
    final shipping = localEstimateShippingAmount;
    if (subtotal == null || shipping == null) return null;
    return subtotal + shipping;
  }

  OrderPricingSummaryState copyWith({
    OrderPricingSummaryStatus? status,
    OrderPricingSummary? summary,
    bool clearSummary = false,
    double? localEstimateSubtotal,
    double? localEstimateShippingAmount,
    bool clearLocalEstimate = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderPricingSummaryState(
      status: status ?? this.status,
      summary: clearSummary ? null : (summary ?? this.summary),
      localEstimateSubtotal: clearLocalEstimate
          ? null
          : (localEstimateSubtotal ?? this.localEstimateSubtotal),
      localEstimateShippingAmount: clearLocalEstimate
          ? null
          : (localEstimateShippingAmount ?? this.localEstimateShippingAmount),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
