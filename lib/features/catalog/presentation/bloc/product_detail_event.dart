sealed class ProductDetailEvent {
  const ProductDetailEvent();
}

/// Starts (or restarts, e.g. navigating from one product straight into
/// another) loading the detail screen for `productId`.
///
/// [origin] is the surface the viewer came from (`grid`, `search`,
/// `favorites`, `share`) — carried through into the `product_viewed`
/// analytics event's `source` parameter, exactly like
/// `ProductGridBloc.ProductGridProductOpened` already logs `source:
/// 'catalog_grid'` for the grid itself.
final class ProductDetailStarted extends ProductDetailEvent {
  const ProductDetailStarted({
    required this.organizationId,
    required this.productId,
    this.origin = 'grid',
  });

  final String organizationId;
  final String productId;
  final String origin;
}

/// Reloads everything from scratch after a failed initial load.
final class ProductDetailRetried extends ProductDetailEvent {
  const ProductDetailRetried();
}

/// The viewer picked a different color swatch: the gallery, the size grid's
/// availability and the "adicionar ao pedido" totals for that color all
/// re-derive from [ProductDetailState] alone — nothing is refetched, since
/// every color's variants/availability were already loaded together.
final class ProductDetailColorSelected extends ProductDetailEvent {
  const ProductDetailColorSelected(this.colorId);

  final String colorId;
}

/// The viewer typed a quantity for one size cell of the currently-selected
/// color's row. Quantities are kept keyed by variant id (color+size), so
/// switching color and back never loses what was already typed elsewhere in
/// the grid (TASK-078 "preservar quantidades digitadas").
final class ProductDetailQuantityChanged extends ProductDetailEvent {
  const ProductDetailQuantityChanged({
    required this.colorId,
    required this.sizeId,
    required this.quantity,
  });

  final String colorId;
  final String sizeId;
  final int quantity;
}

/// The viewer tapped the sticky "Adicionar ao pedido" CTA: logs
/// `product_added_to_order` for every variant with a typed quantity greater
/// than zero. Handing those lines off to an actual order draft (EPIC-13) is
/// the hosting page's job — this bloc never creates or mutates an order,
/// mirroring how `ProductGridPage.onProductSelected` decides navigation
/// while `ProductGridBloc` only logs the tap.
final class ProductDetailAddToOrderRequested extends ProductDetailEvent {
  const ProductDetailAddToOrderRequested();
}
