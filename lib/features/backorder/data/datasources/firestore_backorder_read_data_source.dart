import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/value_objects/backorder_status.dart';
import '../dtos/backorder_request_dto.dart';
import 'backorder_read_data_source.dart';

/// [BackorderReadDataSource] backed directly by `cloud_firestore` (TASK-215)
/// — same "read-only via Rules, write only via Cloud Function" contract
/// `FirestoreFulfillmentReadDataSource` (TASK-214) already follows.
@LazySingleton(as: BackorderReadDataSource)
final class FirestoreBackorderReadDataSource
    implements BackorderReadDataSource {
  FirestoreBackorderReadDataSource(FirebaseFirestore firestore)
    : _backorders = FirestoreCollectionDataSource<BackorderRequestDto>(
        firestore: firestore,
        collectionName: 'backorders',
        converter: FirestoreConverter<BackorderRequestDto>(
          fromJson: (data, id) => BackorderRequestDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<BackorderRequestDto> _backorders;

  static const List<String> _queueableStatusCodes = <String>[
    'queued',
    'ready_to_fulfill',
  ];

  @override
  Stream<List<BackorderRequestDto>> watchQueue({
    required String organizationId,
  }) {
    assert(
      _queueableStatusCodes.toSet().containsAll(
        BackorderStatus.values.where((s) => s.isQueueable).map((s) => s.code),
      ),
      'BackorderStatus.isQueueable drifted from _queueableStatusCodes.',
    );
    return _backorders.watchQuery(
      organizationId: organizationId,
      limit: 300,
      queryBuilder: (query) => query
          .where('status', whereIn: _queueableStatusCodes)
          .orderBy('priorityWeight', descending: true)
          .orderBy('createdAt'),
    );
  }

  @override
  Stream<List<BackorderRequestDto>> watchAwaitingApproval({
    required String organizationId,
  }) {
    return _backorders.watchQuery(
      organizationId: organizationId,
      limit: 200,
      queryBuilder: (query) => query
          .where('status', isEqualTo: 'awaiting_approval')
          .orderBy('createdAt'),
    );
  }

  @override
  Stream<List<BackorderRequestDto>> watchForCustomer({
    required String organizationId,
    required String customerId,
  }) {
    return _backorders.watchQuery(
      organizationId: organizationId,
      limit: 100,
      queryBuilder: (query) => query
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true),
    );
  }
}
