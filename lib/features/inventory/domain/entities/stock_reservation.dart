import '../value_objects/stock_reservation_status.dart';

final class StockReservation {
  const StockReservation({
    required this.id,
    required this.organizationId,
    required this.variantId,
    required this.warehouseId,
    required this.orderDraftId,
    required this.quantity,
    required this.reservedBy,
    required this.reservedAt,
    required this.expiresAt,
    required this.status,
    this.releasedAt,
    this.releasedBy,
    this.consumedAt,
    this.consumedBy,
  });

  final String id;
  final String organizationId;
  final String variantId;
  final String warehouseId;
  final String orderDraftId;
  final int quantity;
  final String reservedBy;
  final DateTime reservedAt;
  final DateTime expiresAt;
  final StockReservationStatus status;
  final DateTime? releasedAt;
  final String? releasedBy;
  final DateTime? consumedAt;
  final String? consumedBy;

  bool get isActive => status == StockReservationStatus.active;
}
