import {
  DEFAULT_INSIGHT_SETTINGS,
  type InsightCustomerSnapshot,
  type InsightRevenueComparisonSnapshot,
} from '../../src/insights/insight-engine';
import { buildInsightsForOrganization } from '../../src/insights/generate-insights-scheduled';

describe('buildInsightsForOrganization', () => {
  it('generates deterministic ids for idempotent rewrites', () => {
    const customerSnapshots: InsightCustomerSnapshot[] = [
      {
        customerId: 'customer-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'seller-1',
        customerName: 'Boutique Aurora',
        customerStatus: 'active',
        segment: 'premium',
        lastOrderAt: new Date('2026-07-01T00:00:00.000Z'),
        lastOrderValue: 3500,
        averageTicket: 4200,
        responsibleSellerId: 'seller-1',
      },
    ];
    const revenueComparisons: InsightRevenueComparisonSnapshot[] = [
      {
        customerId: 'customer-2',
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'seller-2',
        customerName: 'Loja Sol',
        mode: 'yearOverYear',
        currentPeriodRevenue: 9000,
        previousEquivalentRevenue: 15000,
        currentPeriodKey: '2026-08',
        previousPeriodKey: '2025-08',
        currentSeasonCode: 'summer',
        previousSeasonCode: 'summer',
        topCategoryName: 'Vestidos',
        topCategoryRevenueDropAmount: 3800,
      },
    ];

    const firstCycle = buildInsightsForOrganization({
      organizationId: 'org-1',
      asOf: new Date('2026-09-01T12:00:00.000Z'),
      settings: {
        ...DEFAULT_INSIGHT_SETTINGS,
        inactivityThresholdDaysBySegment: { premium: 30 },
      },
      customerSnapshots,
      revenueComparisons,
    });
    const secondCycle = buildInsightsForOrganization({
      organizationId: 'org-1',
      asOf: new Date('2026-09-02T12:00:00.000Z'),
      settings: {
        ...DEFAULT_INSIGHT_SETTINGS,
        inactivityThresholdDaysBySegment: { premium: 30 },
      },
      customerSnapshots,
      revenueComparisons,
    });

    expect(firstCycle).toHaveLength(1);
    expect(secondCycle).toHaveLength(1);
    expect(firstCycle[0].map((item) => item.id)).toEqual(
      secondCycle[0].map((item) => item.id),
    );
    expect(firstCycle[0]).toHaveLength(2);
    expect(secondCycle[0][0].generatedAt.toISOString()).toBe(
      '2026-09-02T12:00:00.000Z',
    );
  });

  it('separates generation by company and skips mismatched seasons', () => {
    const results = buildInsightsForOrganization({
      organizationId: 'org-1',
      asOf: new Date('2026-09-01T12:00:00.000Z'),
      settings: DEFAULT_INSIGHT_SETTINGS,
      customerSnapshots: [
        {
          customerId: 'customer-1',
          organizationId: 'org-1',
          companyId: 'company-a',
          recipientUserId: 'seller-1',
          customerName: 'Cliente A',
          customerStatus: 'active',
          lastOrderAt: new Date('2026-06-01T00:00:00.000Z'),
          averageTicket: 2000,
        },
      ],
      revenueComparisons: [
        {
          customerId: 'customer-2',
          organizationId: 'org-1',
          companyId: 'company-b',
          recipientUserId: 'seller-2',
          customerName: 'Cliente B',
          mode: 'yearOverYear',
          currentPeriodRevenue: 5000,
          previousEquivalentRevenue: 9000,
          currentPeriodKey: '2026-08',
          previousPeriodKey: '2025-08',
          currentSeasonCode: 'winter',
          previousSeasonCode: 'summer',
        },
      ],
    });

    expect(results).toHaveLength(2);
    expect(results[0].length + results[1].length).toBe(1);
    const companies = new Set(
      results.flatMap((items) => items.map((item) => item.companyId)),
    );
    expect(companies).toEqual(new Set<string>(['company-a']));
  });
});
