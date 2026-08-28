import '../../../../core/errors/errors.dart';
import '../../domain/entities/stock_alert.dart';
import '../../domain/value_objects/stock_alert_level.dart';

enum StockAlertListLoadStatus { loading, ready, failure }

const int kStockAlertPageSize = 25;

final class StockAlertListState {
  const StockAlertListState({
    this.loadStatus = StockAlertListLoadStatus.loading,
    this.organizationId = '',
    this.userId = '',
    this.alerts = const <StockAlert>[],
    this.loadFailure,
    this.level,
    this.productId = '',
    this.warehouseId = '',
  });

  final StockAlertListLoadStatus loadStatus;
  final String organizationId;
  final String userId;
  final List<StockAlert> alerts;
  final Failure? loadFailure;
  final StockAlertLevel? level;
  final String productId;
  final String warehouseId;

  bool get hasActiveFilters =>
      level != null ||
      productId.trim().isNotEmpty ||
      warehouseId.trim().isNotEmpty;

  StockAlertListState copyWith({
    StockAlertListLoadStatus? loadStatus,
    String? organizationId,
    String? userId,
    List<StockAlert>? alerts,
    Failure? loadFailure,
    StockAlertLevel? level,
    String? productId,
    String? warehouseId,
    bool clearLoadFailure = false,
    bool clearLevel = false,
    bool clearProductId = false,
    bool clearWarehouseId = false,
  }) {
    return StockAlertListState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      alerts: alerts ?? this.alerts,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      level: clearLevel ? null : level ?? this.level,
      productId: clearProductId ? '' : productId ?? this.productId,
      warehouseId: clearWarehouseId ? '' : warehouseId ?? this.warehouseId,
    );
  }
}
