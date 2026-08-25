import '../../../products/domain/entities/product.dart';

sealed class ProductGridEvent {
  const ProductGridEvent();
}

/// Starts (or restarts, e.g. after switching the active company) the grid:
/// clears any previous state and loads the first page.
final class ProductGridStarted extends ProductGridEvent {
  const ProductGridStarted({required this.organizationId, this.companyId});

  final String organizationId;
  final String? companyId;
}

/// Requests the next page, appending to (never replacing) the products
/// already shown — wired to `AppProductGrid`/`AppPagination`'s "carregar
/// mais" control. A no-op while a page is already loading or when there is
/// no next page (`ProductGridState.hasMore == false`).
final class ProductGridNextPageRequested extends ProductGridEvent {
  const ProductGridNextPageRequested();
}

/// Reloads the first page from scratch after a failed initial load.
final class ProductGridRetried extends ProductGridEvent {
  const ProductGridRetried();
}

/// The viewer tapped a card to open its product detail — logs
/// `product_viewed`. Navigation itself is decided by whoever hosts
/// `ProductGridPage`, never by the bloc.
final class ProductGridProductOpened extends ProductGridEvent {
  const ProductGridProductOpened(this.product);

  final Product product;
}
