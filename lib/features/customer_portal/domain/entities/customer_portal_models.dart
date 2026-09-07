final class CustomerPortalBranding {
  const CustomerPortalBranding({
    required this.name,
    this.logoUrl,
    this.primaryColorHex,
  });
  final String name;
  final String? logoUrl;
  final String? primaryColorHex;
}

final class CustomerPortalProduct {
  const CustomerPortalProduct({
    required this.id,
    required this.name,
    this.imageUrl,
  });
  final String id;
  final String name;
  final String? imageUrl;
}

final class CustomerPortalOrder {
  const CustomerPortalOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
  });
  final String id;
  final String orderNumber;
  final String status;
  final double total;
}

final class RevalidatedPortalItem {
  const RevalidatedPortalItem({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
  });
  final String productId;
  final String variantId;
  final int quantity;
  final double unitPrice;
}

final class CustomerPortalSnapshot {
  const CustomerPortalSnapshot({
    required this.customerId,
    required this.branding,
    required this.products,
    required this.orders,
  });
  final String customerId;
  final CustomerPortalBranding branding;
  final List<CustomerPortalProduct> products;
  final List<CustomerPortalOrder> orders;
}
