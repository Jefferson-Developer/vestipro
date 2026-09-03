/// One row of the Sales Dashboard's drill-down table (TASK-135, seção 12.3
/// de `tasks.md`: "agrupamento"/"ordenação") — one seller, customer, product
/// or category's worth of revenue/orders/quantity/discount for the filtered
/// period, plus its comparison against [SalesDashboardFilters
/// .comparisonPeriod]'s equivalent row (matched by [scopeId]).
///
/// Built exclusively by `LoadSalesDashboardGroupRowsUseCase` from
/// `AggregationSnapshot` rows `AggregationRepository` (TASK-133) already
/// computed — never a client-side scan of raw orders.
final class SalesDashboardGroupRow {
  const SalesDashboardGroupRow({
    required this.scopeId,
    required this.label,
    required this.revenueNet,
    required this.orderCount,
    required this.itemQuantity,
    required this.discountAmount,
    this.previousRevenueNet,
  });

  /// The seller/customer/product/category id this row belongs to — for
  /// `seller`/`customer` rows, the exact id `OrderListFilters.sellerIds`/
  /// `.customerId` expects, so a drill-down into the orders composing this
  /// row can filter by it directly.
  final String scopeId;

  /// Denormalized display label (`AggregationSnapshot.labels`'
  /// `sellerName`/`customerName`/`productName`/`categoryName`) — falls back
  /// to [scopeId] itself when no label was denormalized (e.g. an order
  /// whose customer/seller has since been deleted).
  final String label;

  final double revenueNet;
  final int orderCount;
  final int itemQuantity;
  final double discountAmount;

  /// The same [scopeId]'s `revenueNet` in the comparison period, or `null`
  /// when that scope had no snapshot at all in that period (e.g. a seller
  /// who only started selling this month) — never `0`, so the UI can render
  /// "novo neste período" instead of a misleading "-100%".
  final double? previousRevenueNet;

  /// "Variação percentual" of this row vs. [previousRevenueNet] (seção
  /// 12.3: "comparação de período ... com variação percentual e absoluta
  /// destacada"). `null` when [previousRevenueNet] is unavailable or `0`.
  double? get changePercentage {
    final previous = previousRevenueNet;
    if (previous == null || previous == 0) return null;
    return ((revenueNet - previous) / previous) * 100;
  }

  /// "Variação absoluta" of this row vs. [previousRevenueNet]. `null` when
  /// [previousRevenueNet] is unavailable.
  double? get changeAbsolute {
    final previous = previousRevenueNet;
    if (previous == null) return null;
    return revenueNet - previous;
  }

  double get averageTicket => orderCount == 0 ? 0 : revenueNet / orderCount;

  @override
  bool operator ==(Object other) {
    return other is SalesDashboardGroupRow &&
        scopeId == other.scopeId &&
        label == other.label &&
        revenueNet == other.revenueNet &&
        orderCount == other.orderCount &&
        itemQuantity == other.itemQuantity &&
        discountAmount == other.discountAmount &&
        previousRevenueNet == other.previousRevenueNet;
  }

  @override
  int get hashCode => Object.hash(
    scopeId,
    label,
    revenueNet,
    orderCount,
    itemQuantity,
    discountAmount,
    previousRevenueNet,
  );
}
