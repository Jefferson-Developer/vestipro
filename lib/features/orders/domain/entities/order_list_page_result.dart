import 'order.dart';

/// One cursor-paginated slice of the server's Order collection (TASK-102).
///
/// The cursor is [Order.createdAt] of the last order in [orders], matching
/// the same domain-safe cursor precedent `AuditLogEntryPage`/`StockAlertPage`
/// already use — no Firestore-specific type ever leaves `data/`. Named
/// `...PageResult` (not `OrderListPage`) to avoid colliding with the
/// `OrderListPage` presentation widget — same naming precedent
/// `LeadPageResult`/`CustomerPortfolioPageResult` already set.
final class OrderListPageResult {
  const OrderListPageResult({
    required this.orders,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Order> orders;
  final bool hasMore;
  final DateTime? nextCursor;
}
