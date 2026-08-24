import 'package:injectable/injectable.dart';

import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/value_objects/customer_health_score_band.dart';
import '../entities/crm_activity.dart';
import '../entities/next_best_action.dart';
import '../entities/next_best_action_context.dart';
import '../value_objects/crm_activity_type.dart';
import '../value_objects/next_best_action_priority.dart';
import '../value_objects/next_best_action_type.dart';

@lazySingleton
final class NextBestActionService {
  const NextBestActionService();

  static const int defaultNoContactThresholdDays = 30;

  NextBestAction? recommendForCustomer(NextBestActionContext context) {
    if (!_canRecommend(context)) return null;

    final candidates = <NextBestAction>[
      ?_overdueTaskAction(context),
      ?_healthRiskAction(context),
      ?_noContactAction(context),
    ];
    if (candidates.isEmpty) return null;

    candidates.sort((first, second) {
      final byPriority = second.priority.rank.compareTo(first.priority.rank);
      if (byPriority != 0) return byPriority;
      return first.createdAt.compareTo(second.createdAt);
    });
    return candidates.first;
  }

  List<NextBestAction> recommendForCustomers({
    required Iterable<NextBestActionContext> contexts,
    int limit = 5,
  }) {
    final recommendations =
        contexts.map(recommendForCustomer).nonNulls.toList(growable: false)
          ..sort((first, second) {
            final byPriority = second.priority.rank.compareTo(
              first.priority.rank,
            );
            if (byPriority != 0) return byPriority;
            return first.customerName.compareTo(second.customerName);
          });

    if (limit <= 0 || recommendations.length <= limit) {
      return recommendations;
    }
    return recommendations.take(limit).toList(growable: false);
  }

  bool _canRecommend(NextBestActionContext context) {
    final actorUserId = context.actorUserId.trim();
    if (actorUserId.isEmpty) return false;
    if (context.actorCanManageOthers || context.customerInPortfolio) {
      return true;
    }
    return context.customer.responsibleSellerId?.trim() == actorUserId;
  }

  NextBestAction? _overdueTaskAction(NextBestActionContext context) {
    final now = context.now.toUtc();
    final actorUserId = context.actorUserId.trim();
    final customer = context.customer;
    final tasks =
        context.pendingTasks
            .where(
              (task) =>
                  task.organizationId == customer.organizationId &&
                  task.customerId == customer.id &&
                  task.isOverdue(now) &&
                  task.canBeChangedBy(
                    actorUserId: actorUserId,
                    actorCanManageOthers: context.actorCanManageOthers,
                  ),
            )
            .toList(growable: false)
          ..sort((first, second) {
            final byDue = first.dueAt.compareTo(second.dueAt);
            if (byDue != 0) return byDue;
            return second.priority.index.compareTo(first.priority.index);
          });
    if (tasks.isEmpty) return null;

    final task = tasks.first;
    return NextBestAction(
      id: 'nba:${customer.organizationId}:${customer.id}:task:${task.id}',
      organizationId: customer.organizationId,
      customerId: customer.id,
      customerName: customer.displayName,
      type: NextBestActionType.completeOrRescheduleFollowUp,
      priority: NextBestActionPriority.high,
      suggestedAction: 'Concluir ou reagendar follow-up',
      reason: 'Ha follow-up pendente para este cliente.',
      evidence: 'Tarefa "${task.title}" venceu em ${_dateLabel(task.dueAt)}.',
      createdAt: now,
      relatedTaskId: task.id,
    );
  }

  NextBestAction? _healthRiskAction(NextBestActionContext context) {
    final customer = context.customer;
    if (customer.healthScoreBand != CustomerHealthScoreBand.risk) {
      return null;
    }
    final score = customer.healthScore;
    return NextBestAction(
      id: 'nba:${customer.organizationId}:${customer.id}:health-risk',
      organizationId: customer.organizationId,
      customerId: customer.id,
      customerName: customer.displayName,
      type: NextBestActionType.scheduleVisit,
      priority: NextBestActionPriority.high,
      suggestedAction: 'Planejar visita consultiva',
      reason: score == null
          ? 'Health score indica risco comercial.'
          : 'Health score $score indica risco comercial.',
      evidence: _healthEvidence(customer),
      createdAt: context.now.toUtc(),
      suggestedActivityType: CrmActivityType.visit,
    );
  }

  NextBestAction? _noContactAction(NextBestActionContext context) {
    final customer = context.customer;
    final now = context.now.toUtc();
    final latestActivity = _latestCustomerActivity(
      customer: customer,
      activities: context.activities,
    );
    final referenceDate = latestActivity?.occurredAt ?? customer.registeredAt;
    final daysWithoutContact = _wholeUtcDaysBetween(referenceDate, now);
    if (daysWithoutContact <= context.noContactThresholdDays) {
      return null;
    }

    final evidence = latestActivity == null
        ? 'Sem atividade CRM desde o cadastro em ${_dateLabel(referenceDate)}.'
        : 'Ultima atividade CRM em ${_dateLabel(referenceDate)}.';
    return NextBestAction(
      id: 'nba:${customer.organizationId}:${customer.id}:no-contact',
      organizationId: customer.organizationId,
      customerId: customer.id,
      customerName: customer.displayName,
      type: NextBestActionType.callCustomer,
      priority: NextBestActionPriority.medium,
      suggestedAction: 'Registrar ligacao de acompanhamento',
      reason: 'Cliente sem contato ha $daysWithoutContact dias.',
      evidence: evidence,
      createdAt: now,
      suggestedActivityType: CrmActivityType.phoneCall,
    );
  }

  CrmActivity? _latestCustomerActivity({
    required Customer customer,
    required List<CrmActivity> activities,
  }) {
    final customerActivities =
        activities
            .where(
              (activity) =>
                  activity.organizationId == customer.organizationId &&
                  activity.customerId == customer.id,
            )
            .toList(growable: false)
          ..sort(
            (first, second) => second.occurredAt.compareTo(first.occurredAt),
          );
    if (customerActivities.isEmpty) return null;
    return customerActivities.first;
  }

  String _healthEvidence(Customer customer) {
    final updatedAt = customer.scoreUpdatedAt;
    final coverage = customer.scoreDataCoverage;
    final parts = <String>[
      if (customer.healthScore != null) 'Health score ${customer.healthScore}',
      if (coverage != null) 'cobertura ${coverage.name}',
      if (updatedAt != null) 'atualizado em ${_dateLabel(updatedAt)}',
    ];
    if (parts.isEmpty) return 'Health score classificado como risco.';
    return '${parts.join(' - ')}.';
  }

  int _wholeUtcDaysBetween(DateTime start, DateTime end) {
    final startDay = DateTime.utc(start.year, start.month, start.day);
    final endDay = DateTime.utc(end.year, end.month, end.day);
    return endDay.difference(startDay).inDays;
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
