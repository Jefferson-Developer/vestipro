import '../../domain/value_objects/stock_alert_level.dart';

sealed class StockAlertListEvent {
  const StockAlertListEvent();
}

final class StockAlertListStarted extends StockAlertListEvent {
  const StockAlertListStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class StockAlertListRefreshRequested extends StockAlertListEvent {
  const StockAlertListRefreshRequested();
}

final class StockAlertListFiltersApplied extends StockAlertListEvent {
  const StockAlertListFiltersApplied({
    this.level,
    this.productId = '',
    this.warehouseId = '',
  });

  final StockAlertLevel? level;
  final String productId;
  final String warehouseId;
}

final class StockAlertListFiltersCleared extends StockAlertListEvent {
  const StockAlertListFiltersCleared();
}
