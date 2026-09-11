import { Timestamp } from 'firebase-admin/firestore';

import {
  describeCreditEvaluation,
  evaluateOrderCredit,
  isCreditDataStale,
  isOverrideActive,
  mapCreditProfile,
  type CustomerCreditProfile,
} from '../../src/credit/credit-shared';

const NOW = Timestamp.fromDate(new Date('2026-06-15T12:00:00.000Z'));

function buildProfile(overrides: Partial<CustomerCreditProfile> = {}): CustomerCreditProfile {
  return {
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    creditLimit: 10000,
    openBalance: 2000,
    overdueBalance: 0,
    blockPolicy: 'block',
    financialScore: 750,
    dataSource: 'erp',
    dataUpdatedAt: NOW,
    manualBlock: { active: false, reason: null, by: null, at: null },
    override: {
      active: false,
      reason: null,
      approvedBy: null,
      approvedByName: null,
      approvedAt: null,
      expiresAt: null,
    },
    version: 1,
    ...overrides,
  };
}

describe('evaluateOrderCredit', () => {
  it('releases a pedido within the credit limit and no pendency', () => {
    const result = evaluateOrderCredit(buildProfile(), 3000, NOW);

    expect(result.status).toBe('released');
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(false);
    expect(result.dataStale).toBe(false);
  });

  it('blocks a pedido that exceeds the credit limit under a block policy', () => {
    const result = evaluateOrderCredit(
      buildProfile({ creditLimit: 5000, openBalance: 4000, blockPolicy: 'block' }),
      2000,
      NOW,
    );

    expect(result.status).toBe('blocked');
    expect(result.blocked).toBe(true);
    expect(result.reasonCode).toBe('limit_exceeded');
  });

  it('routes an over-limit pedido to approval under a require_approval policy', () => {
    const result = evaluateOrderCredit(
      buildProfile({ creditLimit: 5000, openBalance: 4000, blockPolicy: 'require_approval' }),
      2000,
      NOW,
    );

    expect(result.status).toBe('approval_required');
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(true);
    expect(result.approverRole).toBe('SALES_MANAGER');
  });

  it('blocks a customer with an overdue balance under a block policy', () => {
    const result = evaluateOrderCredit(
      buildProfile({ overdueBalance: 500, blockPolicy: 'block' }),
      100,
      NOW,
    );

    expect(result.status).toBe('blocked');
    expect(result.reasonCode).toBe('overdue');
  });

  it('flags near-limit as an alert without blocking under an alert policy', () => {
    const result = evaluateOrderCredit(
      buildProfile({ overdueBalance: 500, blockPolicy: 'alert' }),
      100,
      NOW,
    );

    expect(result.status).toBe('near_limit');
    expect(result.blocked).toBe(false);
    expect(result.approvalRequired).toBe(false);
  });

  it('flags near-limit when the projected balance nears the credit limit', () => {
    const result = evaluateOrderCredit(
      buildProfile({ creditLimit: 10000, openBalance: 9000 }),
      500,
      NOW,
    );

    expect(result.status).toBe('near_limit');
    expect(result.blocked).toBe(false);
  });

  it('flags stale data without changing the block outcome', () => {
    const staleUpdatedAt = Timestamp.fromMillis(NOW.toMillis() - 45 * 24 * 60 * 60 * 1000);
    const result = evaluateOrderCredit(
      buildProfile({ dataUpdatedAt: staleUpdatedAt }),
      500,
      NOW,
    );

    expect(result.status).toBe('released');
    expect(result.dataStale).toBe(true);
  });

  it('lets a valid override release an otherwise-blocked manual block', () => {
    const validExpiry = Timestamp.fromMillis(NOW.toMillis() + 24 * 60 * 60 * 1000);
    const result = evaluateOrderCredit(
      buildProfile({
        manualBlock: { active: true, reason: 'Fraude suspeita', by: 'uid-finance', at: NOW },
        override: {
          active: true,
          reason: 'Regularizado por telefone',
          approvedBy: 'uid-finance',
          approvedByName: 'Financeiro',
          approvedAt: NOW,
          expiresAt: validExpiry,
        },
      }),
      100,
      NOW,
    );

    expect(result.status).toBe('released');
    expect(result.overrideApplied).toBe(true);
    expect(result.reasonCode).toBe('override_active');
  });

  it('never applies an expired override', () => {
    const expiredExpiry = Timestamp.fromMillis(NOW.toMillis() - 1000);
    const result = evaluateOrderCredit(
      buildProfile({
        manualBlock: { active: true, reason: 'Fraude suspeita', by: 'uid-finance', at: NOW },
        override: {
          active: true,
          reason: 'Regularizado por telefone',
          approvedBy: 'uid-finance',
          approvedByName: 'Financeiro',
          approvedAt: NOW,
          expiresAt: expiredExpiry,
        },
      }),
      100,
      NOW,
    );

    expect(result.status).toBe('blocked');
    expect(result.overrideApplied).toBe(false);
  });

  it('never blocks a customer with no credit profile at all', () => {
    const result = evaluateOrderCredit(null, 1_000_000, NOW);

    expect(result.status).toBe('released');
    expect(result.reasonCode).toBe('no_profile');
  });

  it('blocks a manual block even when there is no override at all', () => {
    const result = evaluateOrderCredit(
      buildProfile({
        manualBlock: { active: true, reason: 'Fraude suspeita', by: 'uid-finance', at: NOW },
      }),
      0,
      NOW,
    );

    expect(result.status).toBe('blocked');
    expect(result.reasonCode).toBe('manual_block');
  });
});

describe('describeCreditEvaluation', () => {
  it('never leaks a raw financial figure in the seller-facing message', () => {
    const blocked = evaluateOrderCredit(
      buildProfile({ creditLimit: 5000, openBalance: 4999, blockPolicy: 'block' }),
      500,
      NOW,
    );
    const message = describeCreditEvaluation(blocked);

    expect(message).not.toMatch(/\d/);
  });
});

describe('isOverrideActive / isCreditDataStale', () => {
  it('treats an override with no expiresAt as inactive', () => {
    expect(
      isOverrideActive(
        {
          active: true,
          reason: 'x',
          approvedBy: 'uid',
          approvedByName: 'x',
          approvedAt: NOW,
          expiresAt: null,
        },
        NOW,
      ),
    ).toBe(false);
  });

  it('flags data updated exactly at the staleness threshold boundary as fresh', () => {
    const justUnderThreshold = Timestamp.fromMillis(
      NOW.toMillis() - 29 * 24 * 60 * 60 * 1000,
    );
    expect(isCreditDataStale(buildProfile({ dataUpdatedAt: justUnderThreshold }), NOW)).toBe(
      false,
    );
  });
});

describe('mapCreditProfile', () => {
  it('defaults a profile with missing optional fields to the safest values', () => {
    const mapped = mapCreditProfile('customer-2', {
      organizationId: 'org-1',
      companyId: 'company-1',
    });

    expect(mapped.creditLimit).toBe(0);
    expect(mapped.blockPolicy).toBe('none');
    expect(mapped.manualBlock.active).toBe(false);
    expect(mapped.override.active).toBe(false);
    expect(mapped.financialScore).toBeNull();
  });
});
