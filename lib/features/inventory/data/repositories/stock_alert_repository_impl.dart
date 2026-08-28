import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/stock_alert_page.dart';
import '../../domain/repositories/stock_alert_repository.dart';
import '../../domain/value_objects/stock_alert_level.dart';
import '../datasources/stock_alert_data_source.dart';
import '../mappers/stock_alert_mapper.dart';

@LazySingleton(as: StockAlertRepository)
final class StockAlertRepositoryImpl implements StockAlertRepository {
  const StockAlertRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final StockAlertDataSource dataSource;
  final StockAlertMapper mapper;

  @override
  Future<AppResult<StockAlertPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    StockAlertLevel? level,
    String? productId,
    String? warehouseId,
  }) async {
    try {
      final items = await dataSource.listPageByOrganization(
        organizationId: organizationId,
        limit: limit,
        before: before,
        level: level?.code,
        productId: productId,
        warehouseId: warehouseId,
      );
      final alerts = items.map(mapper.toEntity).toList(growable: false);
      return AppSuccess<StockAlertPage>(
        StockAlertPage(
          alerts: alerts,
          hasMore: alerts.length == limit,
          nextCursor: alerts.length == limit && alerts.isNotEmpty
              ? alerts.last.triggeredAt
              : null,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<StockAlertPage>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<StockAlertPage>(
        UnexpectedFailure(
          'Unexpected error listing stock alerts.',
          code: 'stock_alert_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
