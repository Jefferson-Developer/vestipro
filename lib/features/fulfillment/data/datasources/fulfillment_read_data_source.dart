import '../dtos/logistics_issue_dto.dart';
import '../dtos/shipment_dto.dart';
import '../dtos/tracking_event_dto.dart';

abstract interface class FulfillmentReadDataSource {
  Stream<List<ShipmentDto>> watchShipmentsForOrder({
    required String organizationId,
    required String orderId,
  });

  Stream<List<TrackingEventDto>> watchTrackingEvents({
    required String organizationId,
    required String shipmentId,
  });

  Stream<List<LogisticsIssueDto>> watchLogisticsIssues({
    required String organizationId,
    required String shipmentId,
  });
}
