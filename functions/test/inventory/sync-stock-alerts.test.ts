import { Timestamp } from 'firebase-admin/firestore';

import {
  syncStockAlertsForBalanceChange,
  type StockAlertPersistence,
  type StockAlertRecord,
} from '../../src/inventory/sync-stock-alerts';
import type {
  InventoryBalanceSnapshot,
  StockAlertRuleDocument,
} from '../../src/inventory/stock-alert-shared';

function balance(params: {
  version: number;
  physicalQuantity: number;
  reservedQuantity?: number;
  blockedQuantity?: number;
  updatedAt?: Timestamp;
}): InventoryBalanceSnapshot {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    productId: 'product-1',
    variantId: 'variant-1',
    warehouseId: 'wh-1',
    physicalQuantity: params.physicalQuantity,
    reservedQuantity: params.reservedQuantity ?? 0,
    blockedQuantity: params.blockedQuantity ?? 0,
    version: params.version,
    updatedAt: params.updatedAt ?? Timestamp.now(),
    updatedBy: 'owner-1',
    lastSource: 'erp_sync',
  };
}

class InMemoryStockAlertPersistence implements StockAlertPersistence {
  rules: StockAlertRuleDocument[] = [];

  readonly savedAlerts: StockAlertRecord[] = [];

  async listRules(
    organizationId: string,
  ): Promise<ReadonlyArray<StockAlertRuleDocument>> {
    return this.rules.filter((rule) => rule.organizationId === organizationId);
  }

  async saveAlertAndEvent(record: StockAlertRecord): Promise<void> {
    this.savedAlerts.push(record);
  }
}

describe('syncStockAlertsForBalanceChange', () => {
  let persistence: InMemoryStockAlertPersistence;

  beforeEach(() => {
    persistence = new InMemoryStockAlertPersistence();
  });

  it('creates alerts when stock crosses the threshold down and back up', async () => {
    persistence.rules = [
      {
        id: 'rule-low',
        organizationId: 'org-1',
        minQuantity: 5,
        alertLevel: 'low',
        isActive: true,
      },
    ];

    const entered = await syncStockAlertsForBalanceChange(
      balance({ version: 1, physicalQuantity: 9 }),
      balance({ version: 2, physicalQuantity: 4 }),
      persistence,
    );
    const recovered = await syncStockAlertsForBalanceChange(
      balance({ version: 2, physicalQuantity: 4 }),
      balance({ version: 3, physicalQuantity: 8 }),
      persistence,
    );

    expect(entered.createdAlertIds).toEqual(['variant-1_wh-1_v2']);
    expect(recovered.createdAlertIds).toEqual(['variant-1_wh-1_v3']);
    expect(persistence.savedAlerts).toHaveLength(2);
    expect(persistence.savedAlerts[0].transitionType).toBe('entered');
    expect(persistence.savedAlerts[1].transitionType).toBe('recovered');
  });

  it('does not create duplicate alerts for repeated updates below the limit', async () => {
    persistence.rules = [
      {
        id: 'rule-low',
        organizationId: 'org-1',
        minQuantity: 5,
        alertLevel: 'low',
        isActive: true,
      },
    ];

    await syncStockAlertsForBalanceChange(
      balance({ version: 1, physicalQuantity: 8 }),
      balance({ version: 2, physicalQuantity: 4 }),
      persistence,
    );
    const duplicateAttempt = await syncStockAlertsForBalanceChange(
      balance({ version: 2, physicalQuantity: 4 }),
      balance({ version: 3, physicalQuantity: 3 }),
      persistence,
    );

    expect(duplicateAttempt.createdAlertIds).toEqual([]);
    expect(persistence.savedAlerts).toHaveLength(1);
  });

  it('prefers the most specific rule set for the balance', async () => {
    persistence.rules = [
      {
        id: 'org-low',
        organizationId: 'org-1',
        minQuantity: 10,
        alertLevel: 'low',
        isActive: true,
      },
      {
        id: 'variant-critical',
        organizationId: 'org-1',
        variantId: 'variant-1',
        minQuantity: 2,
        alertLevel: 'critical',
        isActive: true,
      },
    ];

    await syncStockAlertsForBalanceChange(
      balance({ version: 1, physicalQuantity: 12 }),
      balance({ version: 2, physicalQuantity: 2 }),
      persistence,
    );

    expect(persistence.savedAlerts).toHaveLength(1);
    expect(persistence.savedAlerts[0].ruleId).toBe('variant-critical');
    expect(persistence.savedAlerts[0].level).toBe('critical');
    expect(persistence.savedAlerts[0].thresholdQuantity).toBe(2);
  });
});
