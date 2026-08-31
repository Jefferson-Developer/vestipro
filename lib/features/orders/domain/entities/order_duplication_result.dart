import 'order.dart';
import 'order_duplication_item_issue.dart';
import 'order_duplication_price_change.dart';

/// Result of successfully "repetindo" a source order through
/// `DuplicateOrderUseCase` (TASK-104).
///
/// [draft] is always a brand new `Order` in [OrderStatus.draft], never the
/// source order's own status/statusHistory — `tasks.md`'s own "nunca herda
/// status ou histórico do pedido original" rule. [priceChanges]/[issues]
/// are purely informative: nothing here blocks the draft from being opened,
/// edited or eventually submitted — the seller decides what to do about
/// them (adjust an item, look for a replacement in the catalog, or just
/// proceed) on `OrderDraftPage` like any other draft.
final class OrderDuplicationResult {
  const OrderDuplicationResult({
    required this.draft,
    required this.sourceOrderId,
    this.sourceOrderNumber,
    this.priceChanges = const <OrderDuplicationPriceChange>[],
    this.issues = const <OrderDuplicationItemIssue>[],
  });

  final Order draft;
  final String sourceOrderId;
  final String? sourceOrderNumber;
  final List<OrderDuplicationPriceChange> priceChanges;
  final List<OrderDuplicationItemIssue> issues;

  bool get hasPriceChanges => priceChanges.isNotEmpty;

  bool get hasIssues => issues.isNotEmpty;

  bool get hasWarnings => hasPriceChanges || hasIssues;
}
