import '../../domain/entities/product_search_source.dart';

sealed class ProductSearchEvent {
  const ProductSearchEvent();
}

final class ProductSearchStarted extends ProductSearchEvent {
  const ProductSearchStarted({
    required this.organizationId,
    this.initialQuery = '',
    this.source = ProductSearchSource.remote,
  });

  final String organizationId;
  final String initialQuery;
  final ProductSearchSource source;
}

final class ProductSearchQueryChanged extends ProductSearchEvent {
  const ProductSearchQueryChanged(this.query);

  final String query;
}

final class ProductSearchSourceChanged extends ProductSearchEvent {
  const ProductSearchSourceChanged(this.source);

  final ProductSearchSource source;
}

final class ProductSearchRetried extends ProductSearchEvent {
  const ProductSearchRetried();
}
