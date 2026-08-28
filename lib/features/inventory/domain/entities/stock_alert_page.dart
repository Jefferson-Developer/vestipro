import 'stock_alert.dart';

final class StockAlertPage {
  const StockAlertPage({
    required this.alerts,
    required this.hasMore,
    this.nextCursor,
  });

  final List<StockAlert> alerts;
  final bool hasMore;
  final DateTime? nextCursor;
}
