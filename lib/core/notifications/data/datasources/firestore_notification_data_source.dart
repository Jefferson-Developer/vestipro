import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../dtos/notification_dto.dart';
import 'notification_data_source.dart';

/// Firestore-backed [NotificationDataSource] for the
/// `organizations/{organizationId}/notifications` subcollection (TASK-151).
///
/// Composes [FirestoreCollectionDataSource] instead of calling
/// `cloud_firestore` directly — same rationale as
/// `FirestorePushDeviceDataSource` — so every read/write is scoped by
/// `organizationId` by construction; per-user isolation on top of that is
/// enforced both by the `userId` query filter here and by
/// `firestore.rules`.
@LazySingleton(as: NotificationDataSource)
final class FirestoreNotificationDataSource implements NotificationDataSource {
  FirestoreNotificationDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<NotificationDto>(
        firestore: firestore,
        collectionName: 'notifications',
        converter: FirestoreConverter<NotificationDto>(
          fromJson: (data, id) => NotificationDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<NotificationDto> _collection;

  @override
  Future<List<NotificationDto>> listForUser({
    required String organizationId,
    required String userId,
    required int limit,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    );
    return page.items;
  }

  @override
  Future<void> create(NotificationDto dto) {
    return _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
  }

  @override
  Future<void> markAsRead({
    required String organizationId,
    required String id,
    required DateTime readAt,
  }) {
    return _collection.update(
      organizationId: organizationId,
      id: id,
      data: {'readAt': Timestamp.fromDate(readAt)},
    );
  }

  @override
  Future<void> markAllAsRead({
    required String organizationId,
    required List<String> ids,
    required DateTime readAt,
  }) async {
    for (final id in ids) {
      await markAsRead(organizationId: organizationId, id: id, readAt: readAt);
    }
  }
}
