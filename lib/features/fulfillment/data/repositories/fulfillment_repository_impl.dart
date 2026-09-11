import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/logistics_issue.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/repositories/fulfillment_repository.dart';
import '../../domain/value_objects/logistics_issue_type.dart';
import '../datasources/fulfillment_read_data_source.dart';
import '../datasources/fulfillment_write_data_source.dart';
import '../mappers/fulfillment_mapper.dart';

@LazySingleton(as: FulfillmentRepository)
final class FulfillmentRepositoryImpl implements FulfillmentRepository {
  const FulfillmentRepositoryImpl(this._readDataSource, this._writeDataSource);

  final FulfillmentReadDataSource _readDataSource;
  final FulfillmentWriteDataSource _writeDataSource;

  @override
  Stream<AppResult<List<Shipment>>> watchShipmentsForOrder({
    required String organizationId,
    required String orderId,
  }) => _watchList(
    _readDataSource.watchShipmentsForOrder(
      organizationId: organizationId,
      orderId: orderId,
    ),
    (dtos) => dtos.map((dto) => dto.toDomain()).toList(growable: false),
    'shipments',
  );

  @override
  Stream<AppResult<List<TrackingEvent>>> watchTrackingEvents({
    required String organizationId,
    required String shipmentId,
  }) => _watchList(
    _readDataSource.watchTrackingEvents(
      organizationId: organizationId,
      shipmentId: shipmentId,
    ),
    (dtos) => dtos.map((dto) => dto.toDomain()).toList(growable: false),
    'trackingEvents',
  );

  @override
  Stream<AppResult<List<LogisticsIssue>>> watchLogisticsIssues({
    required String organizationId,
    required String shipmentId,
  }) => _watchList(
    _readDataSource.watchLogisticsIssues(
      organizationId: organizationId,
      shipmentId: shipmentId,
    ),
    (dtos) => dtos.map((dto) => dto.toDomain()).toList(growable: false),
    'logisticsIssues',
  );

  @override
  Future<AppResult<void>> registerLogisticsIssue({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required LogisticsIssueType type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  }) => _guard(() {
    return _writeDataSource.registerLogisticsIssue(
      organizationId: organizationId,
      companyId: companyId,
      shipmentId: shipmentId,
      logisticsIssueId: logisticsIssueId,
      type: type.code,
      description: description,
      responsibleUserId: responsibleUserId,
      nextAction: nextAction,
    );
  });

  @override
  Future<AppResult<void>> resolveLogisticsIssue({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required bool resolved,
    String? resolutionNote,
  }) => _guard(() {
    return _writeDataSource.resolveLogisticsIssue(
      organizationId: organizationId,
      shipmentId: shipmentId,
      logisticsIssueId: logisticsIssueId,
      status: resolved ? 'resolved' : 'in_progress',
      resolutionNote: resolutionNote,
    );
  });

  Stream<AppResult<List<T>>> _watchList<D, T>(
    Stream<List<D>> source,
    List<T> Function(List<D> dtos) map,
    String label,
  ) async* {
    try {
      await for (final dtos in source) {
        yield AppSuccess<List<T>>(map(dtos));
      }
    } catch (error) {
      yield AppFailure<List<T>>(
        UnexpectedFailure(
          'Unexpected error loading $label.',
          code: 'fulfillment_${label}_watch_unexpected',
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
          'Unexpected error managing fulfillment.',
          code: 'fulfillment_unexpected',
          cause: error,
        ),
      );
    }
  }
}
