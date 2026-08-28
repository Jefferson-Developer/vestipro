import '../dtos/stock_alert_dto.dart';

abstract interface class StockAlertDataSource {
  Future<List<StockAlertDto>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    String? level,
    String? productId,
    String? warehouseId,
  });
}
