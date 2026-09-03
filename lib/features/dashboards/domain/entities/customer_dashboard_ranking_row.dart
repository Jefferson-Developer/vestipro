/// One row of the Customer Dashboard's ranking table (TASK-136, seção 12.3
/// de `tasks.md`: "ordenação"/"agrupamento") — one customer's worth of
/// revenue/orders/quantity for the filtered period, built exclusively by
/// `LoadCustomerDashboardRankingUseCase` from `AggregationSnapshot` rows
/// `AggregationRepository` (TASK-133, `customerMonthly`) already computed —
/// never a client-side scan of raw orders.
final class CustomerDashboardRankingRow {
  const CustomerDashboardRankingRow({
    required this.customerId,
    required this.customerName,
    required this.segment,
    required this.revenueGross,
    required this.revenueNet,
    required this.orderCount,
    required this.itemQuantity,
  });

  /// The exact id a drill-down into `CustomerDetailRoute` (TASK-052) expects.
  final String customerId;

  /// Denormalized display label (`AggregationSnapshot.labels['customerName']`)
  /// — falls back to [customerId] itself when no label was denormalized
  /// (e.g. a customer deleted after the snapshot was written).
  final String customerName;

  /// Denormalized `AggregationSnapshot.labels['segment']` — `null` when the
  /// customer has no segment classified, same "não segmentado" meaning
  /// `CustomerSegmentCriteria` already carries for an absent facet.
  final String? segment;

  final double revenueGross;
  final double revenueNet;
  final int orderCount;
  final int itemQuantity;

  double get averageTicket => orderCount == 0 ? 0 : revenueNet / orderCount;

  @override
  bool operator ==(Object other) {
    return other is CustomerDashboardRankingRow &&
        customerId == other.customerId &&
        customerName == other.customerName &&
        segment == other.segment &&
        revenueGross == other.revenueGross &&
        revenueNet == other.revenueNet &&
        orderCount == other.orderCount &&
        itemQuantity == other.itemQuantity;
  }

  @override
  int get hashCode => Object.hash(
    customerId,
    customerName,
    segment,
    revenueGross,
    revenueNet,
    orderCount,
    itemQuantity,
  );
}
