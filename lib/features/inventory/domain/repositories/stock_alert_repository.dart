import '../../../../core/utils/utils.dart';
import '../entities/stock_alert_page.dart';
import '../value_objects/stock_alert_level.dart';

abstract interface class StockAlertRepository {
  Future<AppResult<StockAlertPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    StockAlertLevel? level,
    String? productId,
    String? warehouseId,
  });
}
