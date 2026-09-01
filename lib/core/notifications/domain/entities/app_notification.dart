enum AppNotificationCategory { targetAlert }

/// Internal notification persisted for the in-app notification center.
final class AppNotification {
  const AppNotification({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String organizationId;
  final String userId;
  final AppNotificationCategory category;
  final String title;
  final String body;
  final String deepLink;
  final DateTime createdAt;
  final DateTime? readAt;
}
