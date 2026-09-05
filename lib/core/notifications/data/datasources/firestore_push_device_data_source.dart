import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../dtos/push_device_dto.dart';
import 'push_device_data_source.dart';

/// Firestore-backed [PushDeviceDataSource] for the
/// `organizations/{organizationId}/pushDevices` subcollection (TASK-150).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly — same rationale as
/// `FirestoreAuditLogDataSource` — so every write is scoped by
/// `organizationId` by construction.
@LazySingleton(as: PushDeviceDataSource)
final class FirestorePushDeviceDataSource implements PushDeviceDataSource {
  FirestorePushDeviceDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<PushDeviceDto>(
        firestore: firestore,
        collectionName: 'pushDevices',
        converter: FirestoreConverter<PushDeviceDto>(
          fromJson: (data, id) => PushDeviceDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<PushDeviceDto> _collection;

  @override
  Future<void> upsert(PushDeviceDto dto) {
    return _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
      merge: true,
    );
  }

  @override
  Future<void> softDelete({
    required String organizationId,
    required String id,
    required DateTime deletedAt,
  }) {
    return _collection.softDelete(
      organizationId: organizationId,
      id: id,
      deletedAt: deletedAt,
    );
  }
}
