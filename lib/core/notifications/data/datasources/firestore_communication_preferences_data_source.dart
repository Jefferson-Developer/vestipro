import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../dtos/communication_preferences_dto.dart';
import 'communication_preferences_data_source.dart';

/// Firestore-backed [CommunicationPreferencesDataSource] for the
/// `organizations/{organizationId}/communicationPreferences` subcollection
/// (TASK-154), one document per user keyed by `userId`.
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly — same rationale as
/// `FirestorePushDeviceDataSource`/`FirestoreNotificationDataSource` — so
/// every read/write is scoped by `organizationId` by construction.
@LazySingleton(as: CommunicationPreferencesDataSource)
final class FirestoreCommunicationPreferencesDataSource
    implements CommunicationPreferencesDataSource {
  FirestoreCommunicationPreferencesDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<CommunicationPreferencesDto>(
        firestore: firestore,
        collectionName: 'communicationPreferences',
        converter: FirestoreConverter<CommunicationPreferencesDto>(
          fromJson: (data, id) =>
              CommunicationPreferencesDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<CommunicationPreferencesDto> _collection;

  @override
  Future<CommunicationPreferencesDto?> getById({
    required String organizationId,
    required String userId,
  }) {
    return _collection.getById(organizationId: organizationId, id: userId);
  }

  @override
  Stream<CommunicationPreferencesDto?> watch({
    required String organizationId,
    required String userId,
  }) {
    return _collection.getStream(organizationId: organizationId, id: userId);
  }

  @override
  Future<void> upsert(CommunicationPreferencesDto dto) {
    return _collection.set(
      organizationId: dto.organizationId,
      id: dto.userId,
      value: dto,
    );
  }
}
