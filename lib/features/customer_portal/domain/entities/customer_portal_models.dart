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
    this.shipmentStatus,
    this.hasOpenLogisticsIssue = false,
    this.estimatedDeliveryDate,
  });
  final String id;
  final String orderNumber;
  final String status;
  final double total;

  /// Rastreio da expedição mais recente deste pedido (TASK-214, EPIC-32) —
  /// `null` enquanto nenhuma expedição foi aberta ainda. Já vem escopado ao
  /// próprio cliente pelo callable `loadCustomerPortal` (Admin SDK); nunca
  /// lido diretamente do Firestore pelo portal.
  final String? shipmentStatus;
  final bool hasOpenLogisticsIssue;
  final DateTime? estimatedDeliveryDate;
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
