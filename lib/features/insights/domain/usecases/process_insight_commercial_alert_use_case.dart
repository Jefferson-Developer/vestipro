import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/notifications/notifications.dart';
import '../../../../core/utils/utils.dart';
import '../entities/insight.dart';
import '../repositories/insight_alert_dispatch_repository.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_type.dart';

/// The [InsightType]s this use case treats as an actual "oportunidade
/// quente" (TASK-153) worth interrupting the recipient for — the positive/
/// upside insights the engine (EPIC-16) produces, as opposed to the
/// risk-flavoured ones (`churnRisk`, `revenueDrop`, `inactiveCustomer`,
/// `highStockLowTurnover`, `sellerBelowTarget`, `abandonedOrder`) that
/// already have their own dedicated surface (Central de Oportunidades,
/// TASK-132) and are not, by themselves, a "quente" sales opportunity in the
/// sense `tasks.md`/VESTI-112 means.
const Set<InsightType> kHotOpportunityInsightTypes = <InsightType>{
  InsightType.crossSell,
  InsightType.upSell,
  InsightType.customerGrowth,
  InsightType.replenishmentSuggestion,
};

/// How long to wait before the same underlying opportunity
/// ([Insight.deduplicationKey]) can notify the same recipient again.
const Duration kInsightCommercialAlertCooldown = Duration(hours: 24);

/// Evaluates a single [Insight] and, when it is a "hot" commercial
/// opportunity ([kHotOpportunityInsightTypes] with `severity` `high`/
/// `critical`), dispatches an internal notification (category `commercial`,
/// TASK-151) to [recipientUserId] — mirrors `ProcessTargetAlertUseCase`
/// (TASK-149)/`ProcessOrderCommercialAlertUseCase` (TASK-153).
///
/// [recipientUserId] is always the caller's own authenticated user, never
/// resolved from [Insight.recipientUserId] blindly: `firestore.rules` only
/// lets a client create a notification for itself, and this [Insight] is
/// only ever fed to this use case because the caller was already authorized
/// to see it (`ListOpportunityCenterInsightsUseCase`'s own
/// `InsightVisibilityService` scoping) — same "RBAC by construction"
/// reasoning `ProcessOrderCommercialAlertUseCase` already documents.
@injectable
final class ProcessInsightCommercialAlertUseCase {
  ProcessInsightCommercialAlertUseCase(
    this._dispatchRepository,
    this._notificationInboxRepository,
    this._shouldDispatchNotification,
    this._analyticsService,
  ) : _uuid = const Uuid();

  final InsightAlertDispatchRepository _dispatchRepository;
  final NotificationInboxRepository _notificationInboxRepository;
  final ShouldDispatchNotificationUseCase _shouldDispatchNotification;
  final AnalyticsService _analyticsService;
  final Uuid _uuid;

  /// Returns `true` when a new notification was actually created for
  /// [insight] — `false` when it does not qualify as a hot opportunity, the
  /// cooldown has not elapsed yet for this recipient, or persisting the
  /// notification failed.
  Future<bool> call({
    required Insight insight,
    required String recipientUserId,
    DateTime? now,
  }) async {
    if (!_isHotOpportunity(insight)) return false;

    final instant = (now ?? DateTime.now()).toUtc();
    final lastDispatchedResult = await _dispatchRepository.getLastDispatchedAt(
      organizationId: insight.organizationId,
      recipientUserId: recipientUserId,
      deduplicationKey: insight.deduplicationKey,
    );
    final lastDispatchedAt = switch (lastDispatchedResult) {
      AppSuccess(value: final value) => value,
      _ => null,
    };
    if (lastDispatchedAt != null &&
        instant.difference(lastDispatchedAt) <
            kInsightCommercialAlertCooldown) {
      return false;
    }

    // TASK-154: never writes the central de notificações entry when the
    // recipient turned `commercial`/central off.
    final allowed = await _shouldDispatchNotification(
      organizationId: insight.organizationId,
      userId: recipientUserId,
      category: AppNotificationCategory.commercial,
    );
    if (!allowed) return false;

    final notification = AppNotification(
      id: _uuid.v4(),
      organizationId: insight.organizationId,
      userId: recipientUserId,
      category: AppNotificationCategory.commercial,
      title: insight.title,
      body: insight.recommendation.trim().isNotEmpty
          ? insight.recommendation
          : insight.description,
      deepLink: _resolveDeepLink(insight),
      createdAt: instant,
      priority: insight.severity == InsightSeverity.critical
          ? AppNotificationPriority.critical
          : AppNotificationPriority.informative,
    );

    final created = await _notificationInboxRepository.create(
      notification: notification,
    );
    if (created is! AppSuccess<AppNotification>) return false;

    await _dispatchRepository.markDispatched(
      organizationId: insight.organizationId,
      recipientUserId: recipientUserId,
      deduplicationKey: insight.deduplicationKey,
      dispatchedAt: instant,
    );
    await _analyticsService.logEvent(
      AnalyticsEvents.commercialOpportunityAlertTriggered,
      parameters: <String, Object?>{
        'organization_id': insight.organizationId,
        'insight_id': insight.id,
        'insight_type': insight.type.name,
        'severity': insight.severity.name,
      },
    );
    return true;
  }

  bool _isHotOpportunity(Insight insight) {
    if (!kHotOpportunityInsightTypes.contains(insight.type)) return false;
    return insight.severity == InsightSeverity.high ||
        insight.severity == InsightSeverity.critical;
  }

  /// Prefers the insight's own [InsightAction.route] — the destination the
  /// Central de Oportunidades' quick action already resolves for this exact
  /// insight — and only falls back to the Central de Oportunidades itself
  /// when it is absent/blank, same "never a broken deep link" precedent
  /// `ProcessCrmTaskReminderUseCase._resolveDeepLink` sets.
  String _resolveDeepLink(Insight insight) {
    final route = insight.quickAction.route?.trim();
    if (route != null && route.isNotEmpty) return route;
    return OpportunityCenterRoute(
      orgId: insight.organizationId,
      companyId: insight.companyId,
    ).location;
  }
}
