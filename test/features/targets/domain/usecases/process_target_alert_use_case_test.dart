import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/targets/targets.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

void main() {
  group('ProcessTargetAlertUseCase', () {
    late _FakeTargetAlertSettingsRepository settingsRepository;
    late _FakeTargetAlertDispatchRepository dispatchRepository;
    late _FakeNotificationInboxRepository notificationInboxRepository;
    late FakeCommunicationPreferencesRepository preferencesRepository;
    late FakeAnalyticsService analyticsService;
    late ProcessTargetAlertUseCase useCase;

    final target = _buildTarget();
    final progress = TargetProgressViewModel.compute(
      target: target,
      realizedValue: 20,
      now: DateTime.utc(2026, 1, 16),
    );

    setUp(() {
      settingsRepository = _FakeTargetAlertSettingsRepository(
        const TargetAlertSettings(
          highRiskPaceRatioThreshold: 0.6,
          moderateRiskPaceRatioThreshold: 0.9,
          notificationCooldown: Duration(hours: 24),
        ),
      );
      dispatchRepository = _FakeTargetAlertDispatchRepository();
      notificationInboxRepository = _FakeNotificationInboxRepository();
      preferencesRepository = FakeCommunicationPreferencesRepository();
      analyticsService = FakeAnalyticsService();
      useCase = ProcessTargetAlertUseCase(
        settingsRepository,
        dispatchRepository,
        notificationInboxRepository,
        ShouldDispatchNotificationUseCase(preferencesRepository),
        ResolveNotificationDeliveryTimeUseCase(preferencesRepository),
        analyticsService,
      );
    });

    test(
      'queues an internal notification with the correct deep link',
      () async {
        final alert = await useCase(
          target: target,
          progress: progress,
          userId: 'rep-1',
          now: DateTime.utc(2026, 1, 16),
        );

        expect(alert, isNotNull);
        expect(alert!.classification, TargetAlertClassification.highRisk);
        expect(alert.notificationQueued, isTrue);
        expect(notificationInboxRepository.items, hasLength(1));
        expect(
          notificationInboxRepository.items.single.deepLink,
          TargetDashboardRoute(
            orgId: 'org-1',
            companyId: 'company-1',
            targetId: 'target-1',
          ).location,
        );
        expect(
          analyticsService.loggedEvents.last.name,
          AnalyticsEvents.targetAlertTriggered,
        );
        // TASK-153: meta em risco alto is the one classification that
        // warrants a critical, visually-distinct notification.
        expect(
          notificationInboxRepository.items.single.priority,
          AppNotificationPriority.critical,
        );
      },
    );

    test('a moderate-risk alert is queued as an informative (non-critical) '
        'notification (TASK-153)', () async {
      final moderateRiskProgress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 35,
        now: DateTime.utc(2026, 1, 16),
      );

      final alert = await useCase(
        target: target,
        progress: moderateRiskProgress,
        userId: 'rep-1',
        now: DateTime.utc(2026, 1, 16),
      );

      expect(alert!.classification, TargetAlertClassification.moderateRisk);
      expect(
        notificationInboxRepository.items.single.priority,
        AppNotificationPriority.informative,
      );
    });

    test(
      'does not duplicate the same alert inside the configured cooldown',
      () async {
        await useCase(
          target: target,
          progress: progress,
          userId: 'rep-1',
          now: DateTime.utc(2026, 1, 16, 9),
        );

        final second = await useCase(
          target: target,
          progress: progress,
          userId: 'rep-1',
          now: DateTime.utc(2026, 1, 16, 18),
        );

        expect(second, isNotNull);
        expect(second!.notificationQueued, isFalse);
        expect(notificationInboxRepository.items, hasLength(1));
        expect(analyticsService.loggedEvents, hasLength(1));
      },
    );

    test('does not queue a notification when the recipient disabled the '
        'commercial/central preference (TASK-154)', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'rep-1',
        ).withChannelFrequency(
          category: AppNotificationCategory.commercial,
          channel: CommunicationChannel.inApp,
          frequency: CommunicationFrequency.disabled,
        ),
      );

      final alert = await useCase(
        target: target,
        progress: progress,
        userId: 'rep-1',
        now: DateTime.utc(2026, 1, 16),
      );

      expect(alert, isNotNull);
      expect(alert!.notificationQueued, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });

    test('a moderate-risk (non-critical) alert is written now with a future '
        'deliverAt when it falls inside the recipient\'s own quiet hours '
        '(TASK-155), never dropped', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'rep-1',
        ).withQuietHours(
          const QuietHours(enabled: true, timezoneOffsetMinutes: 0),
        ),
      );
      final moderateRiskProgress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 35,
        now: DateTime.utc(2026, 1, 16),
      );

      // 00:00 UTC falls inside the default 22:00-07:00 quiet-hours
      // window (with a 0-minute recipient offset, local == UTC here).
      final alert = await useCase(
        target: target,
        progress: moderateRiskProgress,
        userId: 'rep-1',
        now: DateTime.utc(2026, 1, 16),
      );

      expect(alert!.notificationQueued, isTrue);
      expect(notificationInboxRepository.items, hasLength(1));
      expect(
        notificationInboxRepository.items.single.deliverAt,
        DateTime.utc(2026, 1, 16, 7),
      );
    });

    test('a highRisk (critical) alert always reaches the recipient immediately '
        'even during their own quiet hours (TASK-155)', () async {
      preferencesRepository.seed(
        CommunicationPreferences.defaults(
          organizationId: 'org-1',
          userId: 'rep-1',
        ).withQuietHours(
          const QuietHours(enabled: true, timezoneOffsetMinutes: 0),
        ),
      );

      final alert = await useCase(
        target: target,
        progress: progress,
        userId: 'rep-1',
        now: DateTime.utc(2026, 1, 16),
      );

      expect(alert!.classification, TargetAlertClassification.highRisk);
      expect(notificationInboxRepository.items.single.deliverAt, isNull);
    });
  });
}

Target _buildTarget() {
  final createdAt = DateTime.utc(2026, 1, 1);
  return Target(
    id: 'target-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: TargetDimensionType.salesRep,
    dimensionId: 'rep-1',
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: DateTime.utc(2026, 1, 1),
    endDate: DateTime.utc(2026, 2, 1),
    metricType: TargetMetricType.revenue,
    targetValue: 100,
    currency: 'BRL',
    status: TargetStatus.active,
    createdAt: createdAt,
    createdBy: 'manager-1',
    updatedAt: createdAt,
    updatedBy: 'manager-1',
    version: 1,
    syncStatus: TargetSyncStatus.pending,
  );
}

final class _FakeTargetAlertSettingsRepository
    implements TargetAlertSettingsRepository {
  _FakeTargetAlertSettingsRepository(this._settings);

  final TargetAlertSettings _settings;

  @override
  Future<AppResult<TargetAlertSettings>> getForOrganization({
    required String organizationId,
  }) async => AppSuccess<TargetAlertSettings>(_settings);

  @override
  Future<AppResult<TargetAlertSettings>> saveForOrganization({
    required String organizationId,
    required TargetAlertSettings settings,
  }) async => AppSuccess<TargetAlertSettings>(settings);
}

final class _FakeTargetAlertDispatchRepository
    implements TargetAlertDispatchRepository {
  final Map<String, DateTime> _records = <String, DateTime>{};

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
  }) async {
    return AppSuccess<DateTime?>(
      _records['$organizationId::$targetId::${classification.name}'],
    );
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String targetId,
    required TargetAlertClassification classification,
    required DateTime dispatchedAt,
  }) async {
    _records['$organizationId::$targetId::${classification.name}'] =
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
