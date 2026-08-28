enum StockAlertLevel { low, critical }

extension StockAlertLevelCode on StockAlertLevel {
  String get code {
    return switch (this) {
      StockAlertLevel.low => 'low',
      StockAlertLevel.critical => 'critical',
    };
  }
}
