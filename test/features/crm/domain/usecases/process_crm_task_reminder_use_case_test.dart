import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('ProcessCrmTaskReminderUseCase', () {
    late _FakeCrmReminderDispatchRepository dispatchRepository;
    late _FakeNotificationInboxRepository notificationInboxRepository;
    late FakeAnalyticsService analyticsService;
    late ProcessCrmTaskReminderUseCase useCase;

    setUp(() {
      dispatchRepository = _FakeCrmReminderDispatchRepository();
      notificationInboxRepository = _FakeNotificationInboxRepository();
      analyticsService = FakeAnalyticsService();
      useCase = ProcessCrmTaskReminderUseCase(
        dispatchRepository,
        notificationInboxRepository,
        analyticsService,
      );
    });

    // Built from *local* components (no `.utc` factory) then converted to
    // UTC, so `now.toLocal().hour` is guaranteed to be 14 on every machine
    // regardless of its own timezone offset — comfortably inside the
    // default 8h-18h allowed sending window.
    final now = DateTime(2026, 9, 5, 14).toUtc();

    test('dispatches an internal notification to the customer detail deep '
        'link for an overdue own task', () async {
      final task = _buildTask(dueAt: now.subtract(const Duration(hours: 2)));

      final dispatched = await useCase(
        task: task,
        recipientUserId: 'rep-1',
        now: now,
      );

      expect(dispatched, isTrue);
      expect(notificationInboxRepository.items, hasLength(1));
      final notification = notificationInboxRepository.items.single;
      expect(notification.userId, 'rep-1');
      expect(notification.category, AppNotificationCategory.crm);
      expect(
        notification.deepLink,
        CustomerDetailRoute(orgId: 'org-1', customerId: 'customer-1').location,
      );
      expect(
        analyticsService.loggedEvents.last.name,
        AnalyticsEvents.crmReminderTriggered,
      );
    });

    test('does not notify when the task is not overdue nor due soon', () async {
      final task = _buildTask(dueAt: now.add(const Duration(days: 10)));

      final dispatched = await useCase(
        task: task,
        recipientUserId: 'rep-1',
        now: now,
      );

      expect(dispatched, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });

    test('does not duplicate the same task/classification/recipient inside '
        'the cooldown', () async {
      final task = _buildTask(dueAt: now.subtract(const Duration(hours: 2)));

      final first = await useCase(
        task: task,
        recipientUserId: 'rep-1',
        now: now,
      );
      final second = await useCase(
        task: task,
        recipientUserId: 'rep-1',
        now: now.add(const Duration(hours: 1)),
      );

      expect(first, isTrue);
      expect(second, isFalse);
      expect(notificationInboxRepository.items, hasLength(1));
    });

    test('notifies a manager independently from the responsible rep for the '
        'same task, with team-facing wording', () async {
      final task = _buildTask(dueAt: now.subtract(const Duration(hours: 2)));

      await useCase(task: task, recipientUserId: 'rep-1', now: now);
      final managerDispatched = await useCase(
        task: task,
        recipientUserId: 'manager-1',
        now: now,
      );

      expect(managerDispatched, isTrue);
      expect(notificationInboxRepository.items, hasLength(2));
      final managerNotification = notificationInboxRepository.items.last;
      expect(managerNotification.userId, 'manager-1');
      expect(managerNotification.title, contains('equipe'));
    });

    test('does not notify outside the allowed sending window', () async {
      final task = _buildTask(dueAt: now.subtract(const Duration(hours: 2)));
      // Also built from local components, so `.toLocal().hour` is
      // guaranteed to be 23 on every machine — outside the default 8h-18h
      // window.
      final lateNight = DateTime(2026, 9, 5, 23).toUtc();

      final dispatched = await useCase(
        task: task,
        recipientUserId: 'rep-1',
        now: lateNight,
      );

      expect(dispatched, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });

    test('never dispatches when the configured window excludes now', () async {
      final task = _buildTask(dueAt: now.subtract(const Duration(hours: 2)));

      final dispatched = await useCase(
        task: task,
        recipientUserId: 'rep-1',
        now: now,
        settings: const CrmReminderSettings(
          allowedSendingStartHour: 0,
          allowedSendingEndHour: 1,
        ),
      );

      expect(dispatched, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });
  });
}

CrmTask _buildTask({required DateTime dueAt}) {
  final createdAt = DateTime.utc(2026, 9, 1);
  return CrmTask(
    id: 'task-1',
    organizationId: 'org-1',
    title: 'Ligar para o cliente',
    customerId: 'customer-1',
    responsibleUserId: 'rep-1',
    dueAt: dueAt,
    priority: CrmTaskPriority.medium,
    status: CrmTaskStatus.pending,
    createdAt: createdAt,
    createdBy: 'rep-1',
    updatedAt: createdAt,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmTaskSyncStatus.synced,
  );
}

final class _FakeCrmReminderDispatchRepository
    implements CrmReminderDispatchRepository {
  final Map<String, DateTime> _records = <String, DateTime>{};

  String _key(
    String organizationId,
    String taskId,
    String recipientUserId,
    CrmTaskReminderClassification classification,
  ) => '$organizationId::$taskId::$recipientUserId::${classification.name}';

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String taskId,
    required String recipientUserId,
    required CrmTaskReminderClassification classification,
  }) async {
    return AppSuccess<DateTime?>(
      _records[_key(organizationId, taskId, recipientUserId, classification)],
    );
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String taskId,
    required String recipientUserId,
    required CrmTaskReminderClassification classification,
    required DateTime dispatchedAt,
  }) async {
    _records[_key(organizationId, taskId, recipientUserId, classification)] =
        dispatchedAt;
    return AppSuccess<DateTime>(dispatchedAt);
  }
}

final class _FakeNotificationInboxRepository
    implements NotificationInboxRepository {
  final List<AppNotification> items = <AppNotification>[];

  @override
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  }) async {
    items.add(notification);
    return AppSuccess<AppNotification>(notification);
  }

  @override
  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  }) async => AppSuccess<List<AppNotification>>(items);

  @override
  Future<AppResult<void>> markAsRead({
    required String organizationId,
    required String userId,
    required String notificationId,
    DateTime? readAt,
  }) async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> markAllAsRead({
    required String organizationId,
    required String userId,
    DateTime? readAt,
  }) async => const AppSuccess<void>(null);
}
