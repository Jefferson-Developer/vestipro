enum CartShareOutcome { valid, expired, revoked, notFound }

enum CartShareDecision { approved, changesRequested }

final class CartShareItem {
  const CartShareItem({
    required this.itemId,
    required this.productName,
    required this.variantId,
    required this.quantity,
    this.unitPrice,
    this.subtotal,
  });

  final String itemId;
  final String productName;
  final String variantId;
  final int quantity;
  final double? unitPrice;
  final double? subtotal;
}

final class CartSharePreview {
  const CartSharePreview({
    required this.outcome,
    this.organizationName,
    this.showPrices = false,
    this.items = const <CartShareItem>[],
    this.total,
    this.expiresAt,
  });

  final CartShareOutcome outcome;
  final String? organizationName;
  final bool showPrices;
  final List<CartShareItem> items;
  final double? total;
  final DateTime? expiresAt;
}

final class CartShareDraftItem {
  const CartShareDraftItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemId;
  final String productId;
  final String productName;
  final String variantId;
  final int quantity;
  final double unitPrice;
}

final class IssuedCartShare {
  const IssuedCartShare({
    required this.token,
    required this.expiresAt,
    required this.showPrices,
  });
  final String token;
  final DateTime expiresAt;
  final bool showPrices;
}
