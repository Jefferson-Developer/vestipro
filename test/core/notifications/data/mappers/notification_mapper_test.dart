import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/notifications/data/dtos/notification_dto.dart';
import 'package:vestipro/core/notifications/data/mappers/notification_mapper.dart';
import 'package:vestipro/core/notifications/notifications.dart';

void main() {
  group('NotificationMapper', () {
    const mapper = NotificationMapper();

    test('a DTO written before TASK-153 (no priority at all) degrades to '
        'informative instead of throwing', () {
      final dto = NotificationDto(
        id: 'notif-1',
        organizationId: 'org-1',
        userId: 'user-1',
        category: 'commercial',
        title: 'Meta em risco',
        body: 'Seu ritmo está abaixo do necessário.',
        deepLink: '/org/org-1/companies/company-1/targets/dashboard',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final entity = mapper.toEntity(dto);

      expect(entity.priority, AppNotificationPriority.informative);
    });

    test('round-trips a critical priority through toDto/toEntity', () {
      final entity = AppNotification(
        id: 'notif-2',
        organizationId: 'org-1',
        userId: 'user-1',
        category: AppNotificationCategory.commercial,
        title: 'Pedido rejeitado',
        body: 'O pedido 123 foi rejeitado.',
        deepLink: '/org/org-1/companies/company-1/orders/order-1/history',
        createdAt: DateTime.utc(2026, 1, 1),
        priority: AppNotificationPriority.critical,
      );

      final dto = mapper.toDto(entity);
      expect(dto.priority, 'critical');

      final roundTripped = mapper.toEntity(dto);
      expect(roundTripped.priority, AppNotificationPriority.critical);
    });
  });
}
