import 'package:injectable/injectable.dart';

import '../../domain/entities/app_notification.dart';
import '../dtos/notification_dto.dart';

/// Converts between [AppNotification] (domain) and [NotificationDto]
/// (Firestore document shape) — same thin, stateless mapper convention as
/// every other feature's `*Mapper` in this codebase (e.g. `PushDeviceMapper`).
///
/// Explicitly `@lazySingleton` (unlike `PushDeviceMapper`, which the
/// generator resolves via `gh<PushDeviceMapper>()` too but has no matching
/// registration anywhere — a pre-existing gap outside TASK-151's scope):
/// `NotificationInboxRepositoryImpl` is actually constructed through GetIt
/// as soon as `ProcessTargetAlertUseCase` (already wired since TASK-149)
/// resolves it, so an unregistered dependency here would throw at runtime,
/// not just in a build warning.
@lazySingleton
final class NotificationMapper {
  const NotificationMapper();

  AppNotification toEntity(NotificationDto dto) {
    return AppNotification(
      id: dto.id,
      organizationId: dto.organizationId,
      userId: dto.userId,
      category: _categoryFromString(dto.category),
      title: dto.title,
      body: dto.body,
      deepLink: dto.deepLink,
      createdAt: dto.createdAt,
      readAt: dto.readAt,
      priority: _priorityFromString(dto.priority),
      deliverAt: dto.deliverAt,
    );
  }

  NotificationDto toDto(AppNotification entity) {
    return NotificationDto(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      category: entity.category.name,
      title: entity.title,
      body: entity.body,
      deepLink: entity.deepLink,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
      priority: entity.priority.name,
      deliverAt: entity.deliverAt,
    );
  }

  AppNotificationCategory _categoryFromString(String value) {
    return AppNotificationCategory.values.firstWhere(
      (category) => category.name == value,
      // An unrecognized/future category (e.g. written by a newer app
      // version) degrades to `system` instead of crashing the whole list.
      orElse: () => AppNotificationCategory.system,
    );
  }

  AppNotificationPriority _priorityFromString(String value) {
    return AppNotificationPriority.values.firstWhere(
      (priority) => priority.name == value,
      // An unrecognized/future priority, or one absent entirely (every
      // notification written before TASK-153), degrades to `informative`
      // rather than crashing the whole list.
      orElse: () => AppNotificationPriority.informative,
    );
  }
}
