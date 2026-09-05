import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/insights/insights.dart';

import '../../../../support/fake_communication_preferences_repository.dart';

void main() {
  group('ProcessInsightCommercialAlertUseCase', () {
    late _FakeInsightAlertDispatchRepository dispatchRepository;
    late _FakeNotificationInboxRepository notificationInboxRepository;
    late FakeCommunicationPreferencesRepository preferencesRepository;
    late FakeAnalyticsService analyticsService;
    late ProcessInsightCommercialAlertUseCase useCase;

    setUp(() {
      dispatchRepository = _FakeInsightAlertDispatchRepository();
      notificationInboxRepository = _FakeNotificationInboxRepository();
      preferencesRepository = FakeCommunicationPreferencesRepository();
      analyticsService = FakeAnalyticsService();
      useCase = ProcessInsightCommercialAlertUseCase(
        dispatchRepository,
        notificationInboxRepository,
        ShouldDispatchNotificationUseCase(preferencesRepository),
        analyticsService,
      );
    });

    test(
      'dispatches a commercial notification for a hot (high severity) '
      'cross-sell opportunity, deep-linking to the insight quick action',
      () async {
        final insight = _buildInsight(
          type: InsightType.crossSell,
          severity: InsightSeverity.high,
        );

        final dispatched = await useCase(
          insight: insight,
          recipientUserId: 'rep-1',
          now: DateTime.utc(2026, 6, 1),
        );

        expect(dispatched, isTrue);
        expect(notificationInboxRepository.items, hasLength(1));
        final notification = notificationInboxRepository.items.single;
        expect(notification.category, AppNotificationCategory.commercial);
        expect(notification.priority, AppNotificationPriority.informative);
        expect(notification.deepLink, '/org/org-1/customers/customer-1');
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.commercialOpportunityAlertTriggered,
        );
      },
    );

    test(
      'a critical-severity opportunity is a critical-priority notification',
      () async {
        final insight = _buildInsight(
          type: InsightType.upSell,
          severity: InsightSeverity.critical,
        );

        await useCase(
          insight: insight,
          recipientUserId: 'rep-1',
          now: DateTime.utc(2026, 6, 1),
        );

        expect(
          notificationInboxRepository.items.single.priority,
          AppNotificationPriority.critical,
        );
      },
    );

    test(
      'falls back to the Central de Oportunidades with no quick action route',
      () async {
        final insight = _buildInsight(
          type: InsightType.crossSell,
          severity: InsightSeverity.high,
          route: null,
        );

        await useCase(
          insight: insight,
          recipientUserId: 'rep-1',
          now: DateTime.utc(2026, 6, 1),
        );

        expect(
          notificationInboxRepository.items.single.deepLink,
          OpportunityCenterRoute(
            orgId: 'org-1',
            companyId: 'company-1',
          ).location,
        );
      },
    );

    test('does not notify a low-severity opportunity', () async {
      final insight = _buildInsight(
        type: InsightType.crossSell,
        severity: InsightSeverity.low,
      );

      final dispatched = await useCase(
        insight: insight,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1),
      );

      expect(dispatched, isFalse);
      expect(notificationInboxRepository.items, isEmpty);
    });

    test('does not notify a risk-flavoured insight type even at critical '
        'severity — churnRisk has its own surface, is not a "quente" '
        'opportunity', () async {
      final insight = _buildInsight(
        type: InsightType.churnRisk,
        severity: InsightSeverity.critical,
      );

      final dispatched = await useCase(
        insight: insight,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1),
      );

      expect(dispatched, isFalse);
    });

    test('does not re-notify the same opportunity for the same recipient '
        'inside the cooldown, but does after it elapses', () async {
      final insight = _buildInsight(
        type: InsightType.crossSell,
        severity: InsightSeverity.high,
      );

      await useCase(
        insight: insight,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1),
      );
      final withinCooldown = await useCase(
        insight: insight,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 1, 12),
      );
      final afterCooldown = await useCase(
        insight: insight,
        recipientUserId: 'rep-1',
        now: DateTime.utc(2026, 6, 3),
      );

      expect(withinCooldown, isFalse);
      expect(afterCooldown, isTrue);
      expect(notificationInboxRepository.items, hasLength(2));
    });
  });
}

Insight _buildInsight({
  required InsightType type,
  required InsightSeverity severity,
  Object? route = '/org/org-1/customers/customer-1',
}) {
  final now = DateTime.utc(2026, 6, 1);
  return Insight(
    id: 'insight-1',
    type: type,
    title: 'Cliente pronto para cross-sell',
    description: 'O cliente 1 comprou categorias complementares recentemente.',
    estimatedImpact: const InsightEstimatedImpact(amount: 500),
    severity: severity,
    confidenceScore: 0.8,
    recommendation: 'Ofereça a categoria complementar na próxima visita.',
    quickAction: InsightAction(
      type: InsightActionType.openCustomer,
      label: 'Ver cliente',
      route: route as String?,
      customerId: 'customer-1',
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    recipientUserId: 'rep-1',
    customerId: 'customer-1',
    generatedAt: now,
    expiresAt: now.add(const Duration(days: 7)),
    status: InsightStatus.fresh,
  );
}

final class _FakeInsightAlertDispatchRepository
    implements InsightAlertDispatchRepository {
  final Map<String, DateTime> _records = <String, DateTime>{};

  @override
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String recipientUserId,
    required String deduplicationKey,
  }) async {
    return AppSuccess<DateTime?>(
      _records['$organizationId::$recipientUserId::$deduplicationKey'],
    );
  }

  @override
  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String recipientUserId,
    required String deduplicationKey,
    required DateTime dispatchedAt,
  }) async {
    _records['$organizationId::$recipientUserId::$deduplicationKey'] =
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
