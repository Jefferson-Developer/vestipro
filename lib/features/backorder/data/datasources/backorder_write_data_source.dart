abstract interface class BackorderWriteDataSource {
  Future<void> createBackorderRequest({
    required String organizationId,
    required String companyId,
    required String backorderId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required String origin,
    required String priority,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    String? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  });

  Future<void> decideBackorderApproval({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  });

  Future<void> cancelBackorderRequest({
    required String organizationId,
    required String backorderId,
    String? reason,
  });

  Future<void> convertBackorderToOrder({
    required String organizationId,
    required String backorderId,
    required String orderId,
  });
}
