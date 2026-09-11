import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/backorder_request.dart';
import '../../domain/repositories/backorder_repository.dart';
import '../../domain/value_objects/backorder_origin.dart';
import '../../domain/value_objects/backorder_priority.dart';
import '../datasources/backorder_read_data_source.dart';
import '../datasources/backorder_write_data_source.dart';
import '../dtos/backorder_request_dto.dart';
import '../mappers/backorder_mapper.dart';

@LazySingleton(as: BackorderRepository)
final class BackorderRepositoryImpl implements BackorderRepository {
  const BackorderRepositoryImpl(this._readDataSource, this._writeDataSource);

  final BackorderReadDataSource _readDataSource;
  final BackorderWriteDataSource _writeDataSource;

  @override
  Stream<AppResult<List<BackorderRequest>>> watchQueue({
    required String organizationId,
  }) => _watchList(
    _readDataSource.watchQueue(organizationId: organizationId),
    (dtos) => dtos.map((dto) => dto.toDomain()).toList(growable: false),
    'queue',
  );

  @override
  Stream<AppResult<List<BackorderRequest>>> watchAwaitingApproval({
    required String organizationId,
  }) => _watchList(
    _readDataSource.watchAwaitingApproval(organizationId: organizationId),
    (dtos) => dtos.map((dto) => dto.toDomain()).toList(growable: false),
    'awaitingApproval',
  );

  @override
  Stream<AppResult<List<BackorderRequest>>> watchForCustomer({
    required String organizationId,
    required String customerId,
  }) => _watchList(
    _readDataSource.watchForCustomer(
      organizationId: organizationId,
      customerId: customerId,
    ),
    (dtos) => dtos.map((dto) => dto.toDomain()).toList(growable: false),
    'forCustomer',
  );

  @override
  Future<AppResult<void>> createBackorderRequest({
    required String organizationId,
    required String companyId,
    required String backorderId,
    required String customerId,
    required String productId,
    required String variantId,
    String? sku,
    required int quantity,
    required BackorderOrigin origin,
    BackorderPriority priority = BackorderPriority.normal,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    DateTime? requestedDeliveryDate,
    double? estimatedUnitPrice,
    String? notes,
  }) => _guard(() {
    return _writeDataSource.createBackorderRequest(
      organizationId: organizationId,
      companyId: companyId,
      backorderId: backorderId,
      customerId: customerId,
      productId: productId,
      variantId: variantId,
      sku: sku,
      quantity: quantity,
      origin: origin.code,
      priority: priority.code,
      sellerId: sellerId,
      relatedOrderId: relatedOrderId,
      relatedOrderItemId: relatedOrderItemId,
      requestedDeliveryDate: requestedDeliveryDate?.toIso8601String(),
      estimatedUnitPrice: estimatedUnitPrice,
      notes: notes,
    );
  });

  @override
  Future<AppResult<void>> decideBackorderApproval({
    required String organizationId,
    required String backorderId,
    required bool approve,
    String? note,
  }) => _guard(() {
    return _writeDataSource.decideBackorderApproval(
      organizationId: organizationId,
      backorderId: backorderId,
      approve: approve,
      note: note,
    );
  });

  @override
  Future<AppResult<void>> cancelBackorderRequest({
    required String organizationId,
    required String backorderId,
    String? reason,
  }) => _guard(() {
    return _writeDataSource.cancelBackorderRequest(
      organizationId: organizationId,
      backorderId: backorderId,
      reason: reason,
    );
  });

  @override
  Future<AppResult<void>> convertBackorderToOrder({
    required String organizationId,
    required String backorderId,
    required String orderId,
  }) => _guard(() {
    return _writeDataSource.convertBackorderToOrder(
      organizationId: organizationId,
      backorderId: backorderId,
      orderId: orderId,
    );
  });

  Stream<AppResult<List<BackorderRequest>>> _watchList(
    Stream<List<BackorderRequestDto>> source,
    List<BackorderRequest> Function(List<BackorderRequestDto> dtos) map,
    String label,
  ) async* {
    try {
      await for (final dtos in source) {
        yield AppSuccess<List<BackorderRequest>>(map(dtos));
      }
    } catch (error) {
      yield AppFailure<List<BackorderRequest>>(
        UnexpectedFailure(
          'Unexpected error loading backorder $label.',
          code: 'backorder_${label}_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Unexpected error managing backorder.',
          code: 'backorder_unexpected',
          cause: error,
        ),
      );
    }
  }
}
