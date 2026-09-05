import '../dtos/notification_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/notifications/{id}` documents
/// (TASK-151). [FirestoreNotificationDataSource] is the only implementation
/// today.
abstract interface class NotificationDataSource {
  /// Newest first, bounded to [limit].
  Future<List<NotificationDto>> listForUser({
    required String organizationId,
    required String userId,
    required int limit,
  });

  Future<void> create(NotificationDto dto);

  Future<void> markAsRead({
    required String organizationId,
    required String id,
    required DateTime readAt,
  });

  /// Marks every id in [ids] as read with the same [readAt].
  Future<void> markAllAsRead({
    required String organizationId,
    required List<String> ids,
    required DateTime readAt,
  });
}
