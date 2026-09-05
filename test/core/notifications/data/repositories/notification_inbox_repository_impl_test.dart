import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/notifications/data/datasources/notification_data_source.dart';
import 'package:vestipro/core/notifications/data/dtos/notification_dto.dart';
import 'package:vestipro/core/notifications/data/mappers/notification_mapper.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group(
    'NotificationInboxRepositoryImpl — quiet hours visibility (TASK-155)',
    () {
      late _FakeNotificationDataSource dataSource;
      late NotificationInboxRepositoryImpl repository;

      setUp(() {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        dataSource = _FakeNotificationDataSource();
        repository = NotificationInboxRepositoryImpl(
          dataSource,
          const NotificationInboxLocalCache(),
          const NotificationMapper(),
        );
      });

      test('listForUser hides a notification still suppressed by quiet hours '
          '(a future deliverAt), but keeps an already-visible one', () async {
        dataSource.seed(<NotificationDto>[
          _buildDto(id: 'visible-1', deliverAt: null),
          _buildDto(
            id: 'hidden-1',
            deliverAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
          ),
          _buildDto(
            id: 'now-visible-1',
            deliverAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 1),
            ),
          ),
        ]);

        final result = await repository.listForUser(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        final ids = (result as AppSuccess<List<AppNotification>>).value
            .map((notification) => notification.id)
            .toSet();
        expect(ids, <String>{'visible-1', 'now-visible-1'});
      });

      test('a notification created with a future deliverAt is never lost — it '
          'becomes visible once that instant passes, even offline (served from '
          'the local cache)', () async {
        final deliverAt = DateTime.now().toUtc().add(
          const Duration(milliseconds: 50),
        );
        await repository.create(
          notification: AppNotification(
            id: 'deferred-1',
            organizationId: 'org-1',
            userId: 'user-1',
            category: AppNotificationCategory.commercial,
            title: 'Meta abaixo do ritmo',
            body: 'body',
            deepLink: '/deep-link',
            createdAt: DateTime.now().toUtc(),
            deliverAt: deliverAt,
          ),
        );

        dataSource.shouldThrowOnList = true;

        final beforeDue = await repository.listForUser(
          organizationId: 'org-1',
          userId: 'user-1',
        );
        expect((beforeDue as AppSuccess<List<AppNotification>>).value, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 80));

        final afterDue = await repository.listForUser(
          organizationId: 'org-1',
          userId: 'user-1',
        );
        expect(
          (afterDue as AppSuccess<List<AppNotification>>).value.map(
            (notification) => notification.id,
          ),
          <String>['deferred-1'],
        );
      });

      test('markAllAsRead never marks a still-suppressed (future deliverAt) '
          'notification as read', () async {
        await repository.create(
          notification: AppNotification(
            id: 'hidden-2',
            organizationId: 'org-1',
            userId: 'user-1',
            category: AppNotificationCategory.commercial,
            title: 'title',
            body: 'body',
            deepLink: '/deep-link',
            createdAt: DateTime.now().toUtc(),
            deliverAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
        );

        final result = await repository.markAllAsRead(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        expect(result, isA<AppSuccess<void>>());
        expect(dataSource.markedAllAsReadIds, isEmpty);
      });
    },
  );
}

NotificationDto _buildDto({required String id, DateTime? deliverAt}) {
  return NotificationDto(
    id: id,
    organizationId: 'org-1',
    userId: 'user-1',
    category: 'commercial',
    title: 'title',
    body: 'body',
    deepLink: '/deep-link',
    createdAt: DateTime.utc(2026, 1, 1),
    deliverAt: deliverAt,
  );
}

final class _FakeNotificationDataSource implements NotificationDataSource {
  List<NotificationDto> _items = <NotificationDto>[];
  bool shouldThrowOnList = false;
  final List<String> markedAllAsReadIds = <String>[];

  void seed(List<NotificationDto> items) => _items = items;

  @override
  Future<void> create(NotificationDto dto) async {
    _items = <NotificationDto>[dto, ..._items];
  }

  @override
  Future<List<NotificationDto>> listForUser({
    required String organizationId,
    required String userId,
    required int limit,
  }) async {
    if (shouldThrowOnList) {
      throw Exception('offline (simulated)');
    }
    return _items;
  }

  @override
  Future<void> markAllAsRead({
    required String organizationId,
    required List<String> ids,
    required DateTime readAt,
  }) async {
    markedAllAsReadIds.addAll(ids);
  }

  @override
  Future<void> markAsRead({
    required String organizationId,
    required String id,
    required DateTime readAt,
  }) async {}
}
