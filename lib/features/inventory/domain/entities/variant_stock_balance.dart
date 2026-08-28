final class VariantStockBalance {
  const VariantStockBalance({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.productId,
    required this.variantId,
    required this.warehouseId,
    required this.physicalQuantity,
    required this.reservedQuantity,
    required this.blockedQuantity,
    required this.updatedAt,
    required this.updatedBy,
    required this.lastSource,
    required this.version,
    required this.cacheFetchedAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String productId;
  final String variantId;
  final String warehouseId;
  final int physicalQuantity;
  final int reservedQuantity;
  final int blockedQuantity;
  final DateTime updatedAt;
  final String updatedBy;
  final String lastSource;
  final int version;
  final DateTime cacheFetchedAt;

  int get sellableQuantity {
    final value = physicalQuantity - reservedQuantity - blockedQuantity;
    return value < 0 ? 0 : value;
  }
}
