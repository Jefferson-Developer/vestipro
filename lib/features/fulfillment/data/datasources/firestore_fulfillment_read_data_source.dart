import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/logistics_issue_dto.dart';
import '../dtos/shipment_dto.dart';
import '../dtos/tracking_event_dto.dart';
import 'fulfillment_read_data_source.dart';

/// [FulfillmentReadDataSource] backed directly by `cloud_firestore`
/// (TASK-214) — same "read-only via Rules, write only via Cloud Function"
/// contract `FirestoreReceivablesReadDataSource` (TASK-213) already follows.
@LazySingleton(as: FulfillmentReadDataSource)
final class FirestoreFulfillmentReadDataSource
    implements FulfillmentReadDataSource {
  FirestoreFulfillmentReadDataSource(FirebaseFirestore firestore)
    : _shipments = FirestoreCollectionDataSource<ShipmentDto>(
        firestore: firestore,
        collectionName: 'shipments',
        converter: FirestoreConverter<ShipmentDto>(
          fromJson: (data, id) => ShipmentDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      ),
      _trackingEvents = FirestoreCollectionDataSource<TrackingEventDto>(
        firestore: firestore,
        collectionName: 'trackingEvents',
        converter: FirestoreConverter<TrackingEventDto>(
          fromJson: (data, id) => TrackingEventDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      ),
      _logisticsIssues = FirestoreCollectionDataSource<LogisticsIssueDto>(
        firestore: firestore,
        collectionName: 'logisticsIssues',
        converter: FirestoreConverter<LogisticsIssueDto>(
          fromJson: (data, id) => LogisticsIssueDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ShipmentDto> _shipments;
  final FirestoreCollectionDataSource<TrackingEventDto> _trackingEvents;
  final FirestoreCollectionDataSource<LogisticsIssueDto> _logisticsIssues;

  @override
  Stream<List<ShipmentDto>> watchShipmentsForOrder({
    required String organizationId,
    required String orderId,
  }) {
    return _shipments.watchQuery(
      organizationId: organizationId,
      limit: 50,
      queryBuilder: (query) => query
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: false),
    );
  }

  @override
  Stream<List<TrackingEventDto>> watchTrackingEvents({
    required String organizationId,
    required String shipmentId,
  }) {
    return _trackingEvents.watchQuery(
      organizationId: organizationId,
      limit: 200,
      queryBuilder: (query) => query
          .where('shipmentId', isEqualTo: shipmentId)
          .orderBy('occurredAt', descending: false),
    );
  }

  @override
  Stream<List<LogisticsIssueDto>> watchLogisticsIssues({
    required String organizationId,
    required String shipmentId,
  }) {
    return _logisticsIssues.watchQuery(
      organizationId: organizationId,
      limit: 100,
      queryBuilder: (query) => query
          .where('shipmentId', isEqualTo: shipmentId)
          .orderBy('createdAt', descending: true),
    );
  }
}
