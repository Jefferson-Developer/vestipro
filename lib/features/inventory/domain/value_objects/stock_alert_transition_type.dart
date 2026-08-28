enum StockAlertTransitionType { entered, escalated, deescalated, recovered }

extension StockAlertTransitionTypeCode on StockAlertTransitionType {
  String get code {
    return switch (this) {
      StockAlertTransitionType.entered => 'entered',
      StockAlertTransitionType.escalated => 'escalated',
      StockAlertTransitionType.deescalated => 'deescalated',
      StockAlertTransitionType.recovered => 'recovered',
    };
  }
}
