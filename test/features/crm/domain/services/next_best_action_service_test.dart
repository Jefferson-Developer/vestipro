import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/crm/crm.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('NextBestActionService', () {
    const service = NextBestActionService();
    final now = DateTime.utc(2026, 8, 24, 12);

    test('suggests a call when customer has no contact beyond threshold', () {
      final action = service.recommendForCustomer(
        NextBestActionContext(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 31)),
          ),
          actorUserId: 'rep-1',
          actorCanManageOthers: false,
          customerInPortfolio: true,
          now: now,
        ),
      );

      expect(action, isNotNull);
      expect(action!.type, NextBestActionType.callCustomer);
      expect(action.priority, NextBestActionPriority.medium);
      expect(action.suggestedActivityType, CrmActivityType.phoneCall);
      expect(action.reason, contains('31 dias'));
      expect(action.hasTraceableEvidence, isTrue);
    });

    test('does not suggest no-contact action at the threshold boundary', () {
      final action = service.recommendForCustomer(
        NextBestActionContext(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 90)),
          ),
          activities: <CrmActivity>[
            _activity(occurredAt: now.subtract(const Duration(days: 30))),
          ],
          actorUserId: 'rep-1',
          actorCanManageOthers: false,
          customerInPortfolio: true,
          now: now,
        ),
      );

      expect(action, isNull);
    });

    test('suggests a consultative visit when health score is risk', () {
      final action = service.recommendForCustomer(
        NextBestActionContext(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 20)),
            healthScore: 42,
            healthScoreBand: CustomerHealthScoreBand.risk,
          ),
          actorUserId: 'rep-1',
          actorCanManageOthers: false,
          customerInPortfolio: true,
          now: now,
        ),
      );

      expect(action, isNotNull);
      expect(action!.type, NextBestActionType.scheduleVisit);
      expect(action.priority, NextBestActionPriority.high);
      expect(action.suggestedActivityType, CrmActivityType.visit);
      expect(action.reason, contains('Health score 42'));
      expect(action.evidence, contains('Health score 42'));
      expect(action.hasTraceableEvidence, isTrue);
    });

    test('prioritizes overdue follow-up over score and no-contact rules', () {
      final action = service.recommendForCustomer(
        NextBestActionContext(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 80)),
            healthScore: 35,
            healthScoreBand: CustomerHealthScoreBand.risk,
          ),
          pendingTasks: <CrmTask>[
            _task(id: 'task-1', dueAt: now.subtract(const Duration(hours: 2))),
          ],
          actorUserId: 'rep-1',
          actorCanManageOthers: false,
          customerInPortfolio: true,
          now: now,
        ),
      );

      expect(action, isNotNull);
      expect(action!.type, NextBestActionType.completeOrRescheduleFollowUp);
      expect(action.priority, NextBestActionPriority.high);
      expect(action.relatedTaskId, 'task-1');
      expect(action.reason, isNotEmpty);
      expect(action.evidence, contains('Retornar pedido'));
    });

    test('does not leak recommendations outside a seller portfolio', () {
      final customer = _customer(
        responsibleSellerId: 'rep-2',
        registeredAt: now.subtract(const Duration(days: 45)),
      );

      final sellerAction = service.recommendForCustomer(
        NextBestActionContext(
          customer: customer,
          actorUserId: 'rep-1',
          actorCanManageOthers: false,
          customerInPortfolio: false,
          now: now,
        ),
      );
      final managerAction = service.recommendForCustomer(
        NextBestActionContext(
          customer: customer,
          actorUserId: 'manager-1',
          actorCanManageOthers: true,
          customerInPortfolio: false,
          now: now,
        ),
      );

      expect(sellerAction, isNull);
      expect(managerAction, isNotNull);
    });
  });
}

Customer _customer({
  required DateTime registeredAt,
  String responsibleSellerId = 'rep-1',
  int? healthScore,
  CustomerHealthScoreBand? healthScoreBand,
}) {
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Moda Sul Confeccoes Ltda',
    status: CustomerStatus.active,
    responsibleSellerId: responsibleSellerId,
    registeredAt: registeredAt,
    healthScore: healthScore,
    healthScoreBand: healthScoreBand,
    scoreUpdatedAt: healthScoreBand == null
        ? null
        : DateTime.utc(2026, 8, 24, 9),
    scoreFormulaVersion: healthScoreBand == null
        ? null
        : customerScoringFormulaVersion,
    scoreDataCoverage: healthScoreBand == null
        ? null
        : CustomerScoreDataCoverage.ordersAndCrm,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'rep-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CustomerSyncStatus.synced,
  );
}

CrmActivity _activity({required DateTime occurredAt}) {
  return CrmActivity(
    id: 'activity-1',
    organizationId: 'org-1',
    type: CrmActivityType.phoneCall,
    customerId: 'customer-1',
    userId: 'rep-1',
    occurredAt: occurredAt,
    description: 'Ligacao recente',
    createdAt: occurredAt,
    createdBy: 'rep-1',
    updatedAt: occurredAt,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmActivitySyncStatus.synced,
  );
}

CrmTask _task({required String id, required DateTime dueAt}) {
  return CrmTask(
    id: id,
    organizationId: 'org-1',
    title: 'Retornar pedido',
    customerId: 'customer-1',
    responsibleUserId: 'rep-1',
    dueAt: dueAt,
    priority: CrmTaskPriority.high,
    status: CrmTaskStatus.pending,
    createdAt: DateTime.utc(2026, 8, 20),
    createdBy: 'rep-1',
    updatedAt: DateTime.utc(2026, 8, 20),
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmTaskSyncStatus.synced,
  );
}
