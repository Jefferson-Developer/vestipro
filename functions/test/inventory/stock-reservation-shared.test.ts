import { Timestamp } from 'firebase-admin/firestore';
import {
  buildReservationExpiryDate,
  computeSellableQuantity,
  planReservationConsume,
  planReservationCreate,
  planReservationRelease,
  resolveStockReservationTtlMinutes,
  serializeStockReservation,
} from '../../src/inventory/stock-reservation-shared';

describe('stock reservation shared logic', () => {
  it('creates a reservation by moving quantity from sellable into reserved', () => {
    const nextBalance = planReservationCreate(
      {
        physicalQuantity: 10,
        reservedQuantity: 0,
        blockedQuantity: 1,
      },
      4,
    );

    expect(nextBalance).toEqual({
      physicalQuantity: 10,
      reservedQuantity: 4,
      blockedQuantity: 1,
    });
    expect(computeSellableQuantity(nextBalance)).toBe(5);
  });

  it('blocks overselling when the reservation quantity exceeds sellable stock', () => {
    expect(() =>
      planReservationCreate(
        {
          physicalQuantity: 3,
          reservedQuantity: 1,
          blockedQuantity: 1,
        },
        2,
      ),
    ).toThrow('Nao ha saldo vendavel suficiente para reservar esta quantidade.');
  });

  it('releases a reservation by restoring the reserved quantity', () => {
    expect(
      planReservationRelease(
        {
          physicalQuantity: 10,
          reservedQuantity: 4,
          blockedQuantity: 1,
        },
        4,
      ),
    ).toEqual({
      physicalQuantity: 10,
      reservedQuantity: 0,
      blockedQuantity: 1,
    });
  });

  it('consumes a reservation without double-decrementing sellable stock', () => {
    const afterReserve = planReservationCreate(
      {
        physicalQuantity: 10,
        reservedQuantity: 0,
        blockedQuantity: 0,
      },
      4,
    );
    const afterConsume = planReservationConsume(afterReserve, 4);

    expect(afterConsume).toEqual({
      physicalQuantity: 6,
      reservedQuantity: 0,
      blockedQuantity: 0,
    });
    expect(computeSellableQuantity(afterReserve)).toBe(6);
    expect(computeSellableQuantity(afterConsume)).toBe(6);
  });

  it('builds the reservation expiry from the organization ttl', () => {
    const now = new Date('2026-08-28T12:00:00.000Z');
    const expiresAt = buildReservationExpiryDate(now, 45);

    expect(expiresAt.toISOString()).toBe('2026-08-28T12:45:00.000Z');
  });

  it('defaults the organization reservation ttl to 15 minutes when absent', () => {
    expect(resolveStockReservationTtlMinutes({ settings: {} })).toBe(15);
  });

  it('serializes released and consumed timestamps when present', () => {
    const result = serializeStockReservation(
      'reservation-1',
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        productId: 'product-1',
        variantId: 'variant-1',
        warehouseId: 'wh-1',
        orderDraftId: 'draft-1',
        quantity: 4,
        reservedBy: 'rep-1',
        reservedAt: Timestamp.fromDate(new Date('2026-08-28T12:00:00.000Z')),
        expiresAt: Timestamp.fromDate(new Date('2026-08-28T12:15:00.000Z')),
        status: 'consumed',
        releasedAt: Timestamp.fromDate(new Date('2026-08-28T12:05:00.000Z')),
        releasedBy: 'rep-1',
        consumedAt: Timestamp.fromDate(new Date('2026-08-28T12:08:00.000Z')),
        consumedBy: 'rep-1',
      },
      'correlation-1',
    );

    expect(result.status).toBe('consumed');
    expect(result.releasedAt).toBe('2026-08-28T12:05:00.000Z');
    expect(result.consumedAt).toBe('2026-08-28T12:08:00.000Z');
  });
});
