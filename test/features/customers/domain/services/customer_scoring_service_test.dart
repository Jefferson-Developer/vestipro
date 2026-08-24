import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CustomerScoringService', () {
    const service = CustomerScoringService();
    final now = DateTime.utc(2026, 8, 24, 12);

    test('scores an old customer with no order nor CRM activity as risk', () {
      final result = service.calculate(
        CustomerScoringInput(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 420)),
          ),
          now: now,
        ),
      );

      expect(result.commercialScore, lessThan(20));
      expect(result.healthScore, lessThan(50));
      expect(result.healthScoreBand, CustomerHealthScoreBand.risk);
      expect(
        result.scoreDataCoverage,
        CustomerScoreDataCoverage.registrationOnly,
      );
      expect(result.scoreFormulaVersion, customerScoringFormulaVersion);
    });

    test('degrades gracefully for a very recent customer without orders', () {
      final result = service.calculate(
        CustomerScoringInput(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 5)),
          ),
          now: now,
        ),
      );

      expect(result.commercialScore, inInclusiveRange(40, 60));
      expect(result.healthScoreBand, CustomerHealthScoreBand.attention);
      expect(
        result.scoreDataCoverage,
        CustomerScoreDataCoverage.registrationOnly,
      );
    });

    test('caps commercial score when only CRM fallback data is available', () {
      final result = service.calculate(
        CustomerScoringInput(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 300)),
          ),
          now: now,
          crmActivities: <CustomerScoringActivitySignal>[
            CustomerScoringActivitySignal(
              organizationId: 'org-1',
              customerId: 'customer-1',
              occurredAt: now.subtract(const Duration(days: 2)),
            ),
          ],
        ),
      );

      expect(
        result.commercialScore,
        CustomerScoringService.fallbackCommercialScoreCap,
      );
      expect(result.healthScoreBand, CustomerHealthScoreBand.healthy);
      expect(result.scoreDataCoverage, CustomerScoreDataCoverage.crmOnly);
    });

    test('uses RFV order signals when purchase and revenue data exists', () {
      final result = service.calculate(
        CustomerScoringInput(
          customer: _customer(
            registeredAt: now.subtract(const Duration(days: 500)),
            lastPurchaseAt: now.subtract(const Duration(days: 10)),
            potential: 'Alto',
          ),
          now: now,
          purchaseCountLast12Months: 8,
          revenueLast12Months: 75000,
          currentPeriodRevenue: 12000,
          previousPeriodRevenue: 9000,
          crmActivities: <CustomerScoringActivitySignal>[
            CustomerScoringActivitySignal(
              organizationId: 'org-1',
              customerId: 'customer-1',
              occurredAt: now.subtract(const Duration(days: 3)),
            ),
          ],
        ),
      );

      expect(result.commercialScore, 100);
      expect(result.healthScore, 100);
      expect(result.healthScoreBand, CustomerHealthScoreBand.healthy);
      expect(result.scoreDataCoverage, CustomerScoreDataCoverage.ordersAndCrm);
    });

    test('classifies health score bands at documented thresholds', () {
      expect(
        CustomerScoringService.classifyHealthScore(49),
        CustomerHealthScoreBand.risk,
      );
      expect(
        CustomerScoringService.classifyHealthScore(50),
        CustomerHealthScoreBand.attention,
      );
      expect(
        CustomerScoringService.classifyHealthScore(74),
        CustomerHealthScoreBand.attention,
      );
      expect(
        CustomerScoringService.classifyHealthScore(75),
        CustomerHealthScoreBand.healthy,
      );
    });

    test('ignores CRM activity from another organization or customer', () {
      final customer = _customer(
        registeredAt: now.subtract(const Duration(days: 420)),
      );
      final baseline = service.calculate(
        CustomerScoringInput(customer: customer, now: now),
      );
      final polluted = service.calculate(
        CustomerScoringInput(
          customer: customer,
          now: now,
          crmActivities: <CustomerScoringActivitySignal>[
            CustomerScoringActivitySignal(
              organizationId: 'org-2',
              customerId: 'customer-1',
              occurredAt: now.subtract(const Duration(days: 1)),
            ),
            CustomerScoringActivitySignal(
              organizationId: 'org-1',
              customerId: 'customer-2',
              occurredAt: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
      );

      expect(polluted.commercialScore, baseline.commercialScore);
      expect(polluted.healthScore, baseline.healthScore);
      expect(
        polluted.scoreDataCoverage,
        CustomerScoreDataCoverage.registrationOnly,
      );
    });
  });
}

Customer _customer({
  DateTime? registeredAt,
  DateTime? lastPurchaseAt,
  String? potential,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Moda Sul Confeccoes Ltda',
    status: CustomerStatus.active,
    potential: potential,
    registeredAt: registeredAt ?? now,
    lastPurchaseAt: lastPurchaseAt,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.synced,
  );
}
