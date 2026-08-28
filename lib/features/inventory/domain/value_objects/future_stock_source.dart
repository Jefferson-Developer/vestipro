enum FutureStockSource {
  manualForecast,
  purchaseOrder,
  productionOrder,
  transfer,
}

extension FutureStockSourceLabel on FutureStockSource {
  String get label {
    return switch (this) {
      FutureStockSource.manualForecast => 'Previsão manual',
      FutureStockSource.purchaseOrder => 'Compra',
      FutureStockSource.productionOrder => 'Produção',
      FutureStockSource.transfer => 'Transferência',
    };
  }
}
