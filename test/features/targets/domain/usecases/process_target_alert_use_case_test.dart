import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('ProcessTargetAlertUseCase', () {
    late _FakeTargetAlertSettingsRepository settingsRepository;
    late _FakeTargetAlertDispatchRepository dispatchRepository;
    late _FakeNotificationInboxRepository notificationInboxRepository;
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
      analyticsService = FakeAnalyticsService();
      useCase = ProcessTargetAlertUseCase(
        settingsRepository,
        dispatchRepository,
        notificationInboxRepository,
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
      },
    );

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
}
