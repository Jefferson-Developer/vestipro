import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/logistics_issue.dart';
import '../entities/shipment.dart';
import '../entities/tracking_event.dart';
import '../repositories/fulfillment_repository.dart';
import '../value_objects/logistics_issue_type.dart';

@injectable
final class WatchShipmentsForOrderUseCase {
  const WatchShipmentsForOrderUseCase(this._repository);
  final FulfillmentRepository _repository;

  Stream<AppResult<List<Shipment>>> call({
    required String organizationId,
    required String orderId,
  }) => _repository.watchShipmentsForOrder(
    organizationId: organizationId,
    orderId: orderId,
  );
}

@injectable
final class WatchTrackingEventsUseCase {
  const WatchTrackingEventsUseCase(this._repository);
  final FulfillmentRepository _repository;

  Stream<AppResult<List<TrackingEvent>>> call({
    required String organizationId,
    required String shipmentId,
  }) => _repository.watchTrackingEvents(
    organizationId: organizationId,
    shipmentId: shipmentId,
  );
}

@injectable
final class WatchLogisticsIssuesUseCase {
  const WatchLogisticsIssuesUseCase(this._repository);
  final FulfillmentRepository _repository;

  Stream<AppResult<List<LogisticsIssue>>> call({
    required String organizationId,
    required String shipmentId,
  }) => _repository.watchLogisticsIssues(
    organizationId: organizationId,
    shipmentId: shipmentId,
  );
}

@injectable
final class RegisterLogisticsIssueUseCase {
  const RegisterLogisticsIssueUseCase(this._repository);
  final FulfillmentRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required LogisticsIssueType type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  }) => _repository.registerLogisticsIssue(
    organizationId: organizationId,
    companyId: companyId,
    shipmentId: shipmentId,
    logisticsIssueId: logisticsIssueId,
    type: type,
    description: description,
    responsibleUserId: responsibleUserId,
    nextAction: nextAction,
  );
}

@injectable
final class ResolveLogisticsIssueUseCase {
  const ResolveLogisticsIssueUseCase(this._repository);
  final FulfillmentRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required bool resolved,
    String? resolutionNote,
  }) => _repository.resolveLogisticsIssue(
    organizationId: organizationId,
    shipmentId: shipmentId,
    logisticsIssueId: logisticsIssueId,
    resolved: resolved,
    resolutionNote: resolutionNote,
  );
}
