import '../value_objects/stock_alert_level.dart';

final class StockAlertRule {
  const StockAlertRule({
    required this.id,
    required this.organizationId,
    required this.minQuantity,
    required this.alertLevel,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.productId,
    this.variantId,
    this.warehouseId,
  });

  final String id;
  final String organizationId;
  final String? productId;
  final String? variantId;
  final String? warehouseId;
  final int minQuantity;
  final StockAlertLevel alertLevel;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
}
