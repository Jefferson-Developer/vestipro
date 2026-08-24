import { Timestamp } from 'firebase-admin/firestore';
import {
  CUSTOMER_SCORING_FORMULA_VERSION,
  calculateCustomerScore,
  classifyHealthScore,
} from '../../src/customers/customer-scoring-service';
import { buildCustomerScoreUpdate } from '../../src/customers/recalculate-customer-scores';

describe('customer scoring formula v1', () => {
  const now = new Date('2026-08-24T12:00:00.000Z');

  it('scores an old customer with no order nor CRM activity as risk', () => {
    const result = calculateCustomerScore({
      customer: customer({ registeredAt: daysAgo(420, now) }),
      now,
    });

    expect(result.commercialScore).toBeLessThan(20);
    expect(result.healthScore).toBeLessThan(50);
    expect(result.healthScoreBand).toBe('risk');
    expect(result.scoreDataCoverage).toBe('registrationOnly');
    expect(result.scoreFormulaVersion).toBe(CUSTOMER_SCORING_FORMULA_VERSION);
  });

  it('degrades gracefully for a very recent customer without orders', () => {
    const result = calculateCustomerScore({
      customer: customer({ registeredAt: daysAgo(5, now) }),
      now,
    });

    expect(result.commercialScore).toBeGreaterThanOrEqual(40);
    expect(result.commercialScore).toBeLessThanOrEqual(60);
    expect(result.healthScoreBand).toBe('attention');
    expect(result.scoreDataCoverage).toBe('registrationOnly');
  });

  it('caps commercial score when only CRM fallback data is available', () => {
    const result = calculateCustomerScore({
      customer: customer({ registeredAt: daysAgo(300, now) }),
      now,
      crmActivities: [
        {
          organizationId: 'org-1',
          customerId: 'customer-1',
          occurredAt: daysAgo(2, now),
        },
      ],
    });

    expect(result.commercialScore).toBe(60);
    expect(result.healthScoreBand).toBe('healthy');
    expect(result.scoreDataCoverage).toBe('crmOnly');
  });

  it('uses RFV order signals when purchase and revenue data exists', () => {
    const result = calculateCustomerScore({
      customer: customer({
        registeredAt: daysAgo(500, now),
        lastPurchaseAt: daysAgo(10, now),
        potential: 'Alto',
      }),
      now,
      purchaseCountLast12Months: 8,
      revenueLast12Months: 75000,
      currentPeriodRevenue: 12000,
      previousPeriodRevenue: 9000,
      crmActivities: [
        {
          organizationId: 'org-1',
          customerId: 'customer-1',
          occurredAt: daysAgo(3, now),
        },
      ],
    });

    expect(result.commercialScore).toBe(100);
    expect(result.healthScore).toBe(100);
    expect(result.healthScoreBand).toBe('healthy');
    expect(result.scoreDataCoverage).toBe('ordersAndCrm');
  });

  it('classifies health score bands at documented thresholds', () => {
    expect(classifyHealthScore(49)).toBe('risk');
    expect(classifyHealthScore(50)).toBe('attention');
    expect(classifyHealthScore(74)).toBe('attention');
    expect(classifyHealthScore(75)).toBe('healthy');
  });

  it('ignores CRM activity from another organization or customer', () => {
    const target = customer({ registeredAt: daysAgo(420, now) });
    const baseline = calculateCustomerScore({ customer: target, now });
    const polluted = calculateCustomerScore({
      customer: target,
      now,
      crmActivities: [
        {
          organizationId: 'org-2',
          customerId: 'customer-1',
          occurredAt: daysAgo(1, now),
        },
        {
          organizationId: 'org-1',
          customerId: 'customer-2',
          occurredAt: daysAgo(1, now),
        },
      ],
    });

    expect(polluted.commercialScore).toBe(baseline.commercialScore);
    expect(polluted.healthScore).toBe(baseline.healthScore);
    expect(polluted.scoreDataCoverage).toBe('registrationOnly');
  });

  it('builds a partial Firestore update with only score fields', () => {
    const update = buildCustomerScoreUpdate(
      calculateCustomerScore({
        customer: customer({ registeredAt: daysAgo(5, now) }),
        now,
      }),
    );

    expect(Object.keys(update).sort()).toEqual([
      'commercialScore',
      'healthScore',
      'healthScoreBand',
      'scoreDataCoverage',
      'scoreFormulaVersion',
      'scoreUpdatedAt',
    ]);
    expect(update.scoreUpdatedAt).toBeInstanceOf(Timestamp);
  });
});

function customer({
  registeredAt,
  lastPurchaseAt,
  potential,
}: {
  readonly registeredAt: Date;
  readonly lastPurchaseAt?: Date;
  readonly potential?: string;
}) {
  return {
    id: 'customer-1',
    organizationId: 'org-1',
    registeredAt,
    lastPurchaseAt,
    potential,
    status: 'active',
  };
}

function daysAgo(days: number, now: Date): Date {
  return new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
}
