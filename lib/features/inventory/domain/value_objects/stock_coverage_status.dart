enum StockCoverageStatus { ready, noRecentSales, noStockBaseline }

extension StockCoverageStatusCode on StockCoverageStatus {
  String get code {
    return switch (this) {
      StockCoverageStatus.ready => 'ready',
      StockCoverageStatus.noRecentSales => 'noRecentSales',
      StockCoverageStatus.noStockBaseline => 'noStockBaseline',
    };
  }
}
