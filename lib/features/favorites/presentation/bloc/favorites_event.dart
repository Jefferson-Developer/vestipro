import '../../../products/domain/entities/product.dart';

sealed class FavoritesEvent {
  const FavoritesEvent();
}

/// Starts (or restarts) the favorites screen: clears any previous state and
/// loads the first page for the signed-in user.
final class FavoritesStarted extends FavoritesEvent {
  const FavoritesStarted({required this.organizationId, this.companyId});

  final String organizationId;
  final String? companyId;
}

/// Requests the next page, appending to (never replacing) the favorites
/// already shown — wired to `AppProductGrid`/`AppPagination`'s "carregar
/// mais" control, same as `ProductGridNextPageRequested`.
final class FavoritesNextPageRequested extends FavoritesEvent {
  const FavoritesNextPageRequested();
}

/// Reloads the first page from scratch after a failed initial load.
final class FavoritesRetried extends FavoritesEvent {
  const FavoritesRetried();
}

/// The viewer tapped a card to open its product detail — logs
/// `product_viewed`. Navigation itself is decided by whoever hosts
/// `FavoritesPage`, never by the bloc (same contract as
/// `ProductGridProductOpened`).
final class FavoritesProductOpened extends FavoritesEvent {
  const FavoritesProductOpened(this.product);

  final Product product;
}
