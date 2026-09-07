import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

import {
  calculateReplenishmentSuggestionsForOrganization,
  calculateReplenishmentSuggestionsScheduledHandler,
  type ReplenishmentPersistence,
} from '../../src/replenishment/calculate-replenishment-suggestions';
import {
  DEFAULT_REPLENISHMENT_PARAMETERS,
  type ReplenishmentParameters,
  type ReplenishmentVariantStockBalance,
} from '../../src/replenishment/replenishment-calculation-shared';
import type { StockTurnoverDailyFact } from '../../src/inventory/stock-turnover-shared';

function fact(params: {
  organizationId: string;
  dateAt: string;
  variantId: string;
  openingStockQuantity: number;
  receivedQuantity: number;
  soldQuantity: number;
  closingStockQuantity: number;
}): StockTurnoverDailyFact {
  return {
    id: `${params.variantId}_${params.dateAt}`,
    organizationId: params.organizationId,
    dateAt: Timestamp.fromDate(new Date(`${params.dateAt}T00:00:00.000Z`)),
    productId: `product-of-${params.variantId}`,
    variantId: params.variantId,
    collectionId: null,
    warehouseId: null,
    openingStockQuantity: params.openingStockQuantity,
    receivedQuantity: params.receivedQuantity,
    soldQuantity: params.soldQuantity,
    closingStockQuantity: params.closingStockQuantity,
  };
}

function balance(
  overrides: Partial<ReplenishmentVariantStockBalance> = {},
): ReplenishmentVariantStockBalance {
  return {
    id: 'balance-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    productId: 'product-1',
    variantId: 'variant-1',
    warehouseId: 'warehouse-1',
    physicalQuantity: 10,
    reservedQuantity: 0,
    blockedQuantity: 0,
    ...overrides,
  };
}

class InMemoryReplenishmentPersistence implements ReplenishmentPersistence {
  organizationIds: string[] = [];
  settingsByOrganization = new Map<string, ReplenishmentParameters>();
  balancesByOrganization = new Map<string, ReplenishmentVariantStockBalance[]>();
  factsByOrganization = new Map<string, StockTurnoverDailyFact[]>();
  readonly savedSuggestions = new Map<string, DocumentData>();

  async listActiveOrganizationIds(): Promise<ReadonlyArray<string>> {
    return this.organizationIds;
  }

  async loadSettings(organizationId: string): Promise<ReplenishmentParameters> {
    return this.settingsByOrganization.get(organizationId) ?? DEFAULT_REPLENISHMENT_PARAMETERS;
  }

  async listVariantStockBalances(
    organizationId: string,
  ): Promise<ReadonlyArray<ReplenishmentVariantStockBalance>> {
    return this.balancesByOrganization.get(organizationId) ?? [];
  }

  async listStockTurnoverDailyFacts(
    organizationId: string,
    periodStart: Date,
    periodEnd: Date,
  ): Promise<ReadonlyArray<StockTurnoverDailyFact>> {
    const facts = this.factsByOrganization.get(organizationId) ?? [];
    return facts.filter(
      (item) =>
        item.dateAt.toMillis() >= periodStart.getTime() &&
        item.dateAt.toMillis() <= periodEnd.getTime(),
    );
  }

  async loadExistingSuggestionStatus(
    organizationId: string,
    documentId: string,
  ): Promise<string | null> {
    const existing = this.savedSuggestions.get(`${organizationId}/${documentId}`);
    return (existing?.status as string | undefined) ?? null;
  }

  async saveSuggestion(
    organizationId: string,
    documentId: string,
    data: DocumentData,
  ): Promise<void> {
    this.savedSuggestions.set(`${organizationId}/${documentId}`, data);
  }
}

const NOW = new Date('2026-09-07T04:00:00.000Z');

describe('calculateReplenishmentSuggestionsForOrganization', () => {
  it('generates a suggestion for a variant with full turnover history', async () => {
    const persistence = new InMemoryReplenishmentPersistence();
    persistence.balancesByOrganization.set('org-1', [
      balance({ physicalQuantity: 20 }),
    ]);
    persistence.factsByOrganization.set('org-1', [
      fact({
        organizationId: 'org-1',
        dateAt: '2026-09-01',
        variantId: 'variant-1',
        openingStockQuantity: 100,
        receivedQuantity: 0,
        soldQuantity: 10,
        closingStockQuantity: 90,
      }),
      fact({
        organizationId: 'org-1',
        dateAt: '2026-09-02',
        variantId: 'variant-1',
        openingStockQuantity: 90,
        receivedQuantity: 0,
        soldQuantity: 10,
        closingStockQuantity: 80,
      }),
    ]);
    persistence.settingsByOrganization.set('org-1', {
      coverageTargetDays: 10,
      safetyStockQuantity: 0,
      seasonalityFactor: 1,
    });

    const outcome = await calculateReplenishmentSuggestionsForOrganization({
      organizationId: 'org-1',
      now: NOW,
      persistence,
    });

    expect(outcome.generatedCount).toBe(1);
    expect(outcome.skippedFrozenCount).toBe(0);

    const saved = persistence.savedSuggestions.get(
      'org-1/warehouse-1_variant-1_2026-09-07',
    );
    expect(saved).toBeDefined();
    expect(saved!.status).toBe('suggested');
    expect(saved!.currentSellableQuantity).toBe(20);
    // average daily sales = 10/day, coverageTargetDays = 10 -> target = 100
    expect(saved!.targetStockQuantity).toBe(100);
    expect(saved!.suggestedQuantity).toBe(80);
  });

  it('marks insufficientData for a variant with no turnover facts at all', async () => {
    const persistence = new InMemoryReplenishmentPersistence();
    persistence.balancesByOrganization.set('org-1', [
      balance({ variantId: 'brand-new-variant' }),
    ]);

    const outcome = await calculateReplenishmentSuggestionsForOrganization({
      organizationId: 'org-1',
      now: NOW,
      persistence,
    });

    expect(outcome.generatedCount).toBe(1);
    const saved = persistence.savedSuggestions.get(
      'org-1/warehouse-1_brand-new-variant_2026-09-07',
    );
    expect(saved!.status).toBe('insufficientData');
    expect(saved!.insufficientDataReason).toBe('noTurnoverHistory');
    expect(saved!.suggestedQuantity).toBe(0);
  });

  it('is idempotent: re-running the same period overwrites an undecided suggestion', async () => {
    const persistence = new InMemoryReplenishmentPersistence();
    persistence.balancesByOrganization.set('org-1', [balance()]);

    await calculateReplenishmentSuggestionsForOrganization({
      organizationId: 'org-1',
      now: NOW,
      persistence,
    });
    const outcome = await calculateReplenishmentSuggestionsForOrganization({
      organizationId: 'org-1',
      now: NOW,
      persistence,
    });

    expect(outcome.generatedCount).toBe(1);
    expect(outcome.skippedFrozenCount).toBe(0);
    expect(persistence.savedSuggestions.size).toBe(1);
  });

  it('never overwrites a suggestion a human already accepted/adjusted/discarded for the same period', async () => {
    const persistence = new InMemoryReplenishmentPersistence();
    persistence.balancesByOrganization.set('org-1', [balance()]);
    persistence.savedSuggestions.set('org-1/warehouse-1_variant-1_2026-09-07', {
      status: 'accepted',
      suggestedQuantity: 42,
      finalQuantity: 50,
    });

    const outcome = await calculateReplenishmentSuggestionsForOrganization({
      organizationId: 'org-1',
      now: NOW,
      persistence,
    });

    expect(outcome.generatedCount).toBe(0);
    expect(outcome.skippedFrozenCount).toBe(1);
    const saved = persistence.savedSuggestions.get(
      'org-1/warehouse-1_variant-1_2026-09-07',
    );
    // Untouched — still the human decision, not overwritten by the rerun.
    expect(saved!.status).toBe('accepted');
    expect(saved!.finalQuantity).toBe(50);
  });

  it('returns immediately without reading settings/facts when there is no stock balance at all', async () => {
    const persistence = new InMemoryReplenishmentPersistence();

    const outcome = await calculateReplenishmentSuggestionsForOrganization({
      organizationId: 'org-empty',
      now: NOW,
      persistence,
    });

    expect(outcome.generatedCount).toBe(0);
    expect(outcome.skippedFrozenCount).toBe(0);
  });
});

describe('calculateReplenishmentSuggestionsScheduledHandler', () => {
  it('isolates failures per organization: one organization failing never aborts the others', async () => {
    const persistence = new InMemoryReplenishmentPersistence();
    persistence.organizationIds = ['org-broken', 'org-ok'];
    persistence.balancesByOrganization.set('org-ok', [
      balance({ organizationId: 'org-ok' }),
    ]);
    // `org-broken` has no entry in `balancesByOrganization` at all — force a
    // thrown error instead of an empty array, simulating an unexpected
    // failure reading that organization's own data.
    const originalList = persistence.listVariantStockBalances.bind(persistence);
    persistence.listVariantStockBalances = async (organizationId: string) => {
      if (organizationId === 'org-broken') {
        throw new Error('boom');
      }
      return originalList(organizationId);
    };

    await calculateReplenishmentSuggestionsScheduledHandler(NOW, persistence);

    const saved = persistence.savedSuggestions.get(
      'org-ok/warehouse-1_variant-1_2026-09-07',
    );
    expect(saved).toBeDefined();
  });

  it('never mixes stock balances/suggestions across organizations (multi-tenant isolation)', async () => {
    const persistence = new InMemoryReplenishmentPersistence();
    persistence.organizationIds = ['org-a', 'org-b'];
    persistence.balancesByOrganization.set('org-a', [
      balance({ organizationId: 'org-a', variantId: 'variant-a' }),
    ]);
    persistence.balancesByOrganization.set('org-b', [
      balance({ organizationId: 'org-b', variantId: 'variant-b' }),
    ]);

    await calculateReplenishmentSuggestionsScheduledHandler(NOW, persistence);

    expect(
      persistence.savedSuggestions.has('org-a/warehouse-1_variant-a_2026-09-07'),
    ).toBe(true);
    expect(
      persistence.savedSuggestions.has('org-b/warehouse-1_variant-b_2026-09-07'),
    ).toBe(true);
    expect(
      persistence.savedSuggestions.has('org-a/warehouse-1_variant-b_2026-09-07'),
    ).toBe(false);
    expect(
      persistence.savedSuggestions.has('org-b/warehouse-1_variant-a_2026-09-07'),
    ).toBe(false);
  });
});
