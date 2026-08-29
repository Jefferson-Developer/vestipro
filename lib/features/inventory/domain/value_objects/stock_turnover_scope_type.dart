enum StockTurnoverScopeType { product, variant, collection, warehouse }

extension StockTurnoverScopeTypeCode on StockTurnoverScopeType {
  String get code {
    return switch (this) {
      StockTurnoverScopeType.product => 'product',
      StockTurnoverScopeType.variant => 'variant',
      StockTurnoverScopeType.collection => 'collection',
      StockTurnoverScopeType.warehouse => 'warehouse',
    };
  }
}
