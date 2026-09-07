import {
  DEFAULT_REPLENISHMENT_PARAMETERS,
  asReplenishmentVariantStockBalance,
  calculateReplenishmentSuggestion,
  sellableQuantityOf,
  type ReplenishmentTurnoverEvidence,
} from '../../src/replenishment/replenishment-calculation-shared';

function turnover(
  overrides: Partial<ReplenishmentTurnoverEvidence> = {},
): ReplenishmentTurnoverEvidence {
  return {
    averageDailySalesQuantity: 2,
    stockCoverageDays: 10,
    turnoverRate: 0.5,
    coverageStatus: 'ready',
    ...overrides,
  };
}

describe('calculateReplenishmentSuggestion', () => {
  it('suggests enough quantity to reach the coverage target given full turnover history', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ averageDailySalesQuantity: 5 }),
      currentSellableQuantity: 20,
      futureStockQuantity: 0,
      parameters: {
        coverageTargetDays: 30,
        safetyStockQuantity: 10,
        seasonalityFactor: 1,
      },
    });

    // targetStockQuantity = 5 * 30 * 1 + 10 = 160; suggested = 160 - 20 = 140
    expect(result.insufficientData).toBe(false);
    expect(result.targetStockQuantity).toBe(160);
    expect(result.projectedAvailableQuantity).toBe(20);
    expect(result.suggestedQuantity).toBe(140);
  });

  it('accounts for future stock on top of current sellable quantity (partial history)', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ averageDailySalesQuantity: 1 }),
      currentSellableQuantity: 5,
      futureStockQuantity: 10,
      parameters: {
        coverageTargetDays: 20,
        safetyStockQuantity: 0,
        seasonalityFactor: 1,
      },
    });

    // targetStockQuantity = 1 * 20 = 20; projected = 5 + 10 = 15; suggested = 5
    expect(result.targetStockQuantity).toBe(20);
    expect(result.projectedAvailableQuantity).toBe(15);
    expect(result.suggestedQuantity).toBe(5);
  });

  it('applies a seasonality factor above 1 to project higher expected demand', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ averageDailySalesQuantity: 4 }),
      currentSellableQuantity: 0,
      futureStockQuantity: 0,
      parameters: {
        coverageTargetDays: 10,
        safetyStockQuantity: 0,
        seasonalityFactor: 1.5,
      },
    });

    // targetStockQuantity = 4 * 10 * 1.5 = 60
    expect(result.targetStockQuantity).toBe(60);
    expect(result.suggestedQuantity).toBe(60);
  });

  it('marks insufficientData when there is no turnover history at all (brand-new variant)', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: null,
      currentSellableQuantity: 0,
      futureStockQuantity: 0,
      parameters: DEFAULT_REPLENISHMENT_PARAMETERS,
    });

    expect(result.insufficientData).toBe(true);
    expect(result.insufficientDataReason).toBe('noTurnoverHistory');
    expect(result.targetStockQuantity).toBe(0);
    expect(result.suggestedQuantity).toBe(0);
  });

  it('marks insufficientData for noRecentSales coverage status, never fabricating a number', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ coverageStatus: 'noRecentSales', averageDailySalesQuantity: 0 }),
      currentSellableQuantity: 50,
      futureStockQuantity: 0,
      parameters: DEFAULT_REPLENISHMENT_PARAMETERS,
    });

    expect(result.insufficientData).toBe(true);
    expect(result.insufficientDataReason).toBe('noRecentSales');
    expect(result.suggestedQuantity).toBe(0);
  });

  it('marks insufficientData for noStockBaseline coverage status', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ coverageStatus: 'noStockBaseline' }),
      currentSellableQuantity: 0,
      futureStockQuantity: 0,
      parameters: DEFAULT_REPLENISHMENT_PARAMETERS,
    });

    expect(result.insufficientData).toBe(true);
    expect(result.insufficientDataReason).toBe('noStockBaseline');
  });

  it('never suggests a negative quantity when current stock already exceeds the target (zero, not "destock")', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ averageDailySalesQuantity: 1 }),
      currentSellableQuantity: 1000,
      futureStockQuantity: 0,
      parameters: {
        coverageTargetDays: 10,
        safetyStockQuantity: 0,
        seasonalityFactor: 1,
      },
    });

    expect(result.suggestedQuantity).toBe(0);
  });

  it('never suggests a negative quantity from a negative sellable balance (over-reservation edge case)', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ averageDailySalesQuantity: 2 }),
      currentSellableQuantity: -5,
      futureStockQuantity: 0,
      parameters: {
        coverageTargetDays: 5,
        safetyStockQuantity: 0,
        seasonalityFactor: 1,
      },
    });

    // A negative sellable quantity is floored at 0 before projecting, never
    // used to inflate the suggestion further.
    expect(result.projectedAvailableQuantity).toBe(0);
    expect(result.suggestedQuantity).toBe(10);
  });

  it('falls back to a neutral seasonality factor when the configured one is zero/negative', () => {
    const result = calculateReplenishmentSuggestion({
      turnover: turnover({ averageDailySalesQuantity: 2 }),
      currentSellableQuantity: 0,
      futureStockQuantity: 0,
      parameters: {
        coverageTargetDays: 10,
        safetyStockQuantity: 0,
        seasonalityFactor: -1,
      },
    });

    // Should behave as seasonalityFactor = 1, not amplify/invert via a
    // negative multiplier.
    expect(result.targetStockQuantity).toBe(20);
  });
});

describe('sellableQuantityOf', () => {
  it('subtracts reserved and blocked quantities from the physical balance', () => {
    const balance = asReplenishmentVariantStockBalance('balance-1', {
      organizationId: 'org-1',
      companyId: 'company-1',
      productId: 'product-1',
      variantId: 'variant-1',
      warehouseId: 'warehouse-1',
      physicalQuantity: 100,
      reservedQuantity: 30,
      blockedQuantity: 10,
    });

    expect(balance).not.toBeNull();
    expect(sellableQuantityOf(balance!)).toBe(60);
  });

  it('floors at zero instead of going negative', () => {
    const balance = asReplenishmentVariantStockBalance('balance-2', {
      organizationId: 'org-1',
      companyId: 'company-1',
      productId: 'product-1',
      variantId: 'variant-1',
      warehouseId: 'warehouse-1',
      physicalQuantity: 10,
      reservedQuantity: 8,
      blockedQuantity: 5,
    });

    expect(sellableQuantityOf(balance!)).toBe(0);
  });

  it('returns null for a malformed document instead of throwing', () => {
    const balance = asReplenishmentVariantStockBalance('balance-3', {
      organizationId: 'org-1',
      // missing every other required field
    });

    expect(balance).toBeNull();
  });
});
