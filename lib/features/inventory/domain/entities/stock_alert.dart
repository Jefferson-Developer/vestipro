import '../value_objects/stock_alert_level.dart';
import '../value_objects/stock_alert_transition_type.dart';

final class StockAlert {
  const StockAlert({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.productId,
    required this.variantId,
    required this.warehouseId,
    required this.level,
    required this.transitionType,
    required this.sellableQuantity,
    required this.thresholdQuantity,
    required this.triggeredAt,
    required this.ruleId,
    required this.notificationEventId,
    this.previousLevel,
    this.currentLevel,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String productId;
  final String variantId;
  final String warehouseId;
  final StockAlertLevel level;
  final StockAlertLevel? previousLevel;
  final StockAlertLevel? currentLevel;
  final StockAlertTransitionType transitionType;
  final int sellableQuantity;
  final int thresholdQuantity;
  final DateTime triggeredAt;
  final String ruleId;
  final String notificationEventId;

  bool get isActive => currentLevel != null;
}
