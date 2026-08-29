import '../value_objects/stock_turnover_scope_type.dart';

final class StockTurnoverMetricScope {
  const StockTurnoverMetricScope({required this.type, required this.id});

  final StockTurnoverScopeType type;
  final String id;
}
